begin;

-- PER-2 claim / heartbeat / transition / retry / wake runtime.
CREATE OR REPLACE FUNCTION public.control_room_claim_project_graph_node_v2(p_run_key text, p_node_key text, p_claim_key text, p_lease_seconds integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_existing public.control_room_project_graph_node_transitions_v2%rowtype;
  v_request jsonb;
  v_request_hash text;
  v_phase text;
  v_token uuid;
  v_lease_seconds integer;
  v_lease_expires_at timestamptz;
  v_response jsonb;
  v_runtime jsonb;
begin
  if p_claim_key is null or btrim(p_claim_key) = '' or char_length(p_claim_key) > 240 then
    raise exception 'invalid_claim_key' using errcode = 'P0001';
  end if;

  if p_lease_seconds is not null and (p_lease_seconds < 1 or p_lease_seconds > 86400) then
    raise exception 'invalid_lease_seconds' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'kind','claim',
    'run_key',p_run_key,
    'node_key',p_node_key,
    'lease_seconds',p_lease_seconds
  );
  v_request_hash := md5(v_request::text);

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    raise exception 'graph_runtime_version_mismatch:expected=2,actual=%',
      v_graph.runtime_version using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.control_room_project_graph_node_transitions_v2
  where graph_run_key = p_run_key
    and transition_key = p_claim_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'transition_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'claim', v_existing.response,
        'idempotent_transition_replay', true
      );
  end if;

  if v_graph.status in ('completed','failed','cancelled') then
    raise exception 'graph_run_not_executable:%', v_graph.status using errcode = 'P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  if v_node.status = 'ready' then
    if v_node.attempt_count >= v_node.max_attempts then
      raise exception 'node_attempt_budget_exhausted' using errcode = 'P0001';
    end if;

    v_phase := 'execute';

    perform public.control_room_checkpoint_run_v1(
      p_run_key,
      v_graph.project_id,
      null,
      'active',
      1,
      0,
      0,
      0,
      null,
      null,
      null,
      null,
      p_node_key,
      null
    );
  elsif v_node.status = 'verifying' then
    if v_node.execution_token is not null then
      if v_node.lease_expires_at is not null and v_node.lease_expires_at <= clock_timestamp() then
        raise exception 'node_lease_expired_wake_required' using errcode = 'P0001';
      end if;
      raise exception 'node_already_leased' using errcode = 'P0001';
    end if;

    v_phase := case
      when v_node.recovery_policy = 'reconcile' then 'reconcile'
      else 'verify'
    end;
  else
    raise exception 'node_not_claimable:%', v_node.status using errcode = 'P0001';
  end if;

  v_lease_seconds := least(
    coalesce(p_lease_seconds, v_node.timeout_seconds),
    v_node.timeout_seconds
  );

  if v_lease_seconds < 1 then
    raise exception 'invalid_effective_lease_seconds' using errcode = 'P0001';
  end if;

  v_token := gen_random_uuid();
  v_lease_expires_at := clock_timestamp() + make_interval(secs => v_lease_seconds);

  update public.control_room_project_graph_nodes_v1
  set
    status = case when status = 'ready' then 'running' else status end,
    attempt_count = attempt_count + case when status = 'ready' then 1 else 0 end,
    execution_epoch = execution_epoch + 1,
    execution_token = v_token,
    heartbeat_at = clock_timestamp(),
    lease_expires_at = v_lease_expires_at,
    started_at = case when status = 'ready' then coalesce(started_at, now()) else started_at end,
    wait_context = '{}'::jsonb,
    wait_started_at = null,
    updated_at = now()
  where id = v_node.id
  returning * into v_node;

  v_response := jsonb_build_object(
    'node_key', v_node.node_key,
    'phase', v_phase,
    'lease_token', v_token,
    'lease_expires_at', v_lease_expires_at,
    'execution_epoch', v_node.execution_epoch,
    'attempt_count', v_node.attempt_count
  );

  insert into public.control_room_project_graph_node_transitions_v2(
    graph_run_key,
    node_id,
    transition_key,
    request_hash,
    transition_kind,
    from_status,
    to_status,
    phase,
    lease_token,
    request,
    response
  )
  values(
    p_run_key,
    v_node.id,
    p_claim_key,
    v_request_hash,
    'claim',
    case when v_phase = 'execute' then 'ready' else 'verifying' end,
    v_node.status,
    v_phase,
    v_token,
    v_request,
    v_response
  );

  v_runtime := public.control_room_refresh_project_graph_v2(p_run_key);

  return v_runtime
    || jsonb_build_object(
      'claim', v_response,
      'idempotent_transition_replay', false
    );
end;
$$;

CREATE OR REPLACE FUNCTION public.control_room_heartbeat_project_graph_node_v2(p_run_key text, p_node_key text, p_lease_token uuid, p_heartbeat_key text, p_extend_seconds integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_existing public.control_room_project_graph_node_transitions_v2%rowtype;
  v_request jsonb;
  v_request_hash text;
  v_extend_seconds integer;
  v_expires_at timestamptz;
  v_response jsonb;
begin
  if p_heartbeat_key is null or btrim(p_heartbeat_key) = '' or char_length(p_heartbeat_key) > 240 then
    raise exception 'invalid_heartbeat_key' using errcode = 'P0001';
  end if;

  if p_lease_token is null then
    raise exception 'lease_token_required' using errcode = 'P0001';
  end if;

  if p_extend_seconds is not null and (p_extend_seconds < 1 or p_extend_seconds > 86400) then
    raise exception 'invalid_extend_seconds' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'kind','heartbeat',
    'run_key',p_run_key,
    'node_key',p_node_key,
    'lease_token',p_lease_token,
    'extend_seconds',p_extend_seconds
  );
  v_request_hash := md5(v_request::text);

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    raise exception 'graph_runtime_version_mismatch:expected=2,actual=%',
      v_graph.runtime_version using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.control_room_project_graph_node_transitions_v2
  where graph_run_key = p_run_key
    and transition_key = p_heartbeat_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'transition_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'heartbeat', v_existing.response,
        'idempotent_transition_replay', true
      );
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  if v_node.status not in ('running','verifying') then
    raise exception 'node_not_heartbeatable:%', v_node.status using errcode = 'P0001';
  end if;

  if v_node.execution_token is distinct from p_lease_token then
    raise exception 'invalid_lease_token' using errcode = 'P0001';
  end if;

  if v_node.lease_expires_at is null or v_node.lease_expires_at <= clock_timestamp() then
    raise exception 'node_lease_expired_wake_required' using errcode = 'P0001';
  end if;

  v_extend_seconds := least(
    coalesce(p_extend_seconds, v_node.timeout_seconds),
    v_node.timeout_seconds
  );

  v_expires_at := clock_timestamp() + make_interval(secs => v_extend_seconds);

  update public.control_room_project_graph_nodes_v1
  set
    heartbeat_at = clock_timestamp(),
    lease_expires_at = v_expires_at,
    updated_at = now()
  where id = v_node.id;

  v_response := jsonb_build_object(
    'node_key', v_node.node_key,
    'lease_token', p_lease_token,
    'lease_expires_at', v_expires_at
  );

  insert into public.control_room_project_graph_node_transitions_v2(
    graph_run_key,
    node_id,
    transition_key,
    request_hash,
    transition_kind,
    from_status,
    to_status,
    phase,
    lease_token,
    request,
    response
  )
  values(
    p_run_key,
    v_node.id,
    p_heartbeat_key,
    v_request_hash,
    'heartbeat',
    v_node.status,
    v_node.status,
    'heartbeat',
    p_lease_token,
    v_request,
    v_response
  );

  return public.control_room_get_project_graph_runtime_v2(p_run_key)
    || jsonb_build_object(
      'heartbeat', v_response,
      'idempotent_transition_replay', false
    );
end;
$$;

CREATE OR REPLACE FUNCTION public.control_room_retry_project_graph_node_v2(p_run_key text, p_node_key text, p_retry_key text, p_evidence jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_existing public.control_room_project_graph_node_transitions_v2%rowtype;
  v_request jsonb;
  v_request_hash text;
  v_response jsonb;
  v_runtime jsonb;
begin
  if p_retry_key is null or btrim(p_retry_key) = '' or char_length(p_retry_key) > 240 then
    raise exception 'invalid_retry_key' using errcode = 'P0001';
  end if;

  if p_evidence is null or jsonb_typeof(p_evidence) <> 'object' then
    raise exception 'evidence_object_required' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'kind','retry',
    'run_key',p_run_key,
    'node_key',p_node_key,
    'evidence',p_evidence
  );
  v_request_hash := md5(v_request::text);

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    raise exception 'graph_runtime_version_mismatch:expected=2,actual=%',
      v_graph.runtime_version using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.control_room_project_graph_node_transitions_v2
  where graph_run_key = p_run_key
    and transition_key = p_retry_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'transition_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'retry', v_existing.response,
        'idempotent_transition_replay', true
      );
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  if v_node.status <> 'failed' then
    raise exception 'node_not_failed' using errcode = 'P0001';
  end if;

  if v_node.failure_policy not in ('retry','repair','fallback') then
    raise exception 'node_failure_policy_not_retryable' using errcode = 'P0001';
  end if;

  if v_node.attempt_count >= v_node.max_attempts then
    raise exception 'node_attempt_budget_exhausted' using errcode = 'P0001';
  end if;

  perform public.control_room_checkpoint_run_v1(
    p_run_key,
    v_graph.project_id,
    null,
    'active',
    0,
    0,
    1,
    0,
    null,
    null,
    null,
    null,
    p_node_key,
    null
  );

  update public.control_room_project_graph_nodes_v1
  set
    status = 'ready',
    result = null,
    evidence = evidence || p_evidence || jsonb_build_object('retry_requested_at', now()),
    execution_token = null,
    heartbeat_at = null,
    lease_expires_at = null,
    wait_context = '{}'::jsonb,
    wait_started_at = null,
    completed_at = null,
    updated_at = now()
  where id = v_node.id
  returning * into v_node;

  v_response := jsonb_build_object(
    'node_key',v_node.node_key,
    'status','ready',
    'attempt_count',v_node.attempt_count
  );

  insert into public.control_room_project_graph_node_transitions_v2(
    graph_run_key,
    node_id,
    transition_key,
    request_hash,
    transition_kind,
    from_status,
    to_status,
    phase,
    lease_token,
    request,
    response
  )
  values(
    p_run_key,
    v_node.id,
    p_retry_key,
    v_request_hash,
    'retry',
    'failed',
    'ready',
    'retry',
    null,
    v_request,
    v_response
  );

  v_runtime := public.control_room_refresh_project_graph_v2(p_run_key);

  return v_runtime
    || jsonb_build_object(
      'retry', v_response,
      'idempotent_transition_replay', false
    );
end;
$$;

CREATE OR REPLACE FUNCTION public.control_room_transition_project_graph_node_v2(p_run_key text, p_node_key text, p_transition_key text, p_expected_status text, p_new_status text, p_lease_token uuid DEFAULT NULL::uuid, p_result jsonb DEFAULT NULL::jsonb, p_evidence jsonb DEFAULT '{}'::jsonb, p_wait_context jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_existing public.control_room_project_graph_node_transitions_v2%rowtype;
  v_request jsonb;
  v_request_hash text;
  v_work_unit_key text;
  v_checkpoint jsonb;
  v_response jsonb;
  v_runtime jsonb;
begin
  if p_transition_key is null or btrim(p_transition_key) = '' or char_length(p_transition_key) > 240 then
    raise exception 'invalid_transition_key' using errcode = 'P0001';
  end if;

  if p_evidence is null or jsonb_typeof(p_evidence) <> 'object' then
    raise exception 'evidence_object_required' using errcode = 'P0001';
  end if;

  if p_wait_context is null or jsonb_typeof(p_wait_context) <> 'object' then
    raise exception 'wait_context_object_required' using errcode = 'P0001';
  end if;

  if p_result is not null and jsonb_typeof(p_result) <> 'object' then
    raise exception 'result_object_required' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'kind','state',
    'run_key',p_run_key,
    'node_key',p_node_key,
    'expected_status',p_expected_status,
    'new_status',p_new_status,
    'lease_token',p_lease_token,
    'result',p_result,
    'evidence',p_evidence,
    'wait_context',p_wait_context
  );
  v_request_hash := md5(v_request::text);

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    raise exception 'graph_runtime_version_mismatch:expected=2,actual=%',
      v_graph.runtime_version using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.control_room_project_graph_node_transitions_v2
  where graph_run_key = p_run_key
    and transition_key = p_transition_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'transition_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'transition', v_existing.response,
        'idempotent_transition_replay', true
      );
  end if;

  if v_graph.status in ('completed','failed','cancelled') then
    raise exception 'graph_run_not_executable:%', v_graph.status using errcode = 'P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  if v_node.status <> p_expected_status then
    raise exception 'node_status_conflict:expected=%,actual=%',
      p_expected_status, v_node.status using errcode = 'P0001';
  end if;

  if not (
    (v_node.status = 'ready' and p_new_status in ('waiting_session','waiting_owner','skipped','cancelled'))
    or (v_node.status = 'running' and p_new_status in ('verifying','completed','failed','waiting_session','waiting_owner'))
    or (v_node.status = 'verifying' and p_new_status in ('completed','failed','ready','waiting_session','waiting_owner'))
    or (v_node.status = 'waiting_session' and p_new_status in ('ready','cancelled'))
    or (v_node.status = 'waiting_owner' and p_new_status in ('ready','cancelled'))
  ) then
    raise exception 'invalid_node_transition:%->%', v_node.status, p_new_status using errcode = 'P0001';
  end if;

  if v_node.status in ('running','verifying') then
    if v_node.execution_token is null then
      raise exception 'node_not_leased' using errcode = 'P0001';
    end if;

    if v_node.execution_token is distinct from p_lease_token then
      raise exception 'invalid_lease_token' using errcode = 'P0001';
    end if;

    if v_node.lease_expires_at is null or v_node.lease_expires_at <= clock_timestamp() then
      raise exception 'node_lease_expired_wake_required' using errcode = 'P0001';
    end if;
  end if;

  if v_node.status = 'verifying' and p_new_status = 'ready'
     and coalesce(p_evidence->>'reconciled_absent','false') <> 'true' then
    raise exception 'reconcile_absence_evidence_required' using errcode = 'P0001';
  end if;

  update public.control_room_project_graph_nodes_v1
  set
    status = p_new_status,
    result = case when p_result is not null then p_result else result end,
    evidence = evidence || p_evidence,
    execution_token = case
      when p_new_status = 'verifying' then execution_token
      else null
    end,
    heartbeat_at = case
      when p_new_status = 'verifying' then heartbeat_at
      else null
    end,
    lease_expires_at = case
      when p_new_status = 'verifying' then lease_expires_at
      else null
    end,
    wait_context = case
      when p_new_status in ('waiting_session','waiting_owner') then p_wait_context
      else '{}'::jsonb
    end,
    wait_started_at = case
      when p_new_status in ('waiting_session','waiting_owner') then coalesce(wait_started_at, now())
      else null
    end,
    completed_at = case
      when p_new_status in ('completed','failed','skipped','cancelled') then now()
      when p_new_status = 'ready' then null
      else completed_at
    end,
    updated_at = now()
  where id = v_node.id
  returning * into v_node;

  if p_new_status = 'completed' then
    select w.work_unit_key into v_work_unit_key
    from public.control_room_project_graph_runs_v1 g
    join public.control_room_project_work_units_v1 w on w.id = g.work_unit_id
    where g.run_key = p_run_key;

    select jsonb_build_object(
      'work_unit_key', v_work_unit_key,
      'graph_run_key', p_run_key,
      'completed_nodes', coalesce(
        jsonb_agg(node_key order by node_index, node_key)
          filter (where status = 'completed'),
        '[]'::jsonb
      ),
      'last_completed_node', p_node_key,
      'checkpointed_at', now()
    )
    into v_checkpoint
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key;

    update public.control_room_run_envelopes
    set last_verified_checkpoint = v_checkpoint, updated_at = now()
    where run_key = p_run_key;

    update public.control_room_project_graph_exceptions_v1
    set
      status = 'resolved',
      resolved_at = now(),
      resolution = jsonb_build_object(
        'reason','node_completed',
        'transition_key',p_transition_key
      ),
      updated_at = now()
    where graph_run_key = p_run_key
      and node_id = v_node.id
      and status = 'open';
  end if;

  v_response := jsonb_build_object(
    'node_key', v_node.node_key,
    'from_status', p_expected_status,
    'to_status', p_new_status,
    'execution_epoch', v_node.execution_epoch,
    'attempt_count', v_node.attempt_count
  );

  insert into public.control_room_project_graph_node_transitions_v2(
    graph_run_key,
    node_id,
    transition_key,
    request_hash,
    transition_kind,
    from_status,
    to_status,
    phase,
    lease_token,
    request,
    response
  )
  values(
    p_run_key,
    v_node.id,
    p_transition_key,
    v_request_hash,
    'state',
    p_expected_status,
    p_new_status,
    case
      when p_expected_status = 'verifying' then 'verify'
      else 'execute'
    end,
    p_lease_token,
    v_request,
    v_response
  );

  v_runtime := public.control_room_refresh_project_graph_v2(p_run_key);

  return v_runtime
    || jsonb_build_object(
      'transition', v_response,
      'idempotent_transition_replay', false
    );
end;
$$;

CREATE OR REPLACE FUNCTION public.control_room_wake_project_graph_v2(p_run_key text, p_wake_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_existing public.control_room_project_graph_wakes_v2%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_request jsonb;
  v_request_hash text;
  v_recovered jsonb := '[]'::jsonb;
  v_recovery_mode text;
  v_to_status text;
  v_exception_key text;
  v_transition_key text;
  v_transition_request jsonb;
  v_transition_response jsonb;
  v_response jsonb;
  v_runtime jsonb;
begin
  if p_wake_key is null or btrim(p_wake_key) = '' or char_length(p_wake_key) > 240 then
    raise exception 'invalid_wake_key' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'kind','wake',
    'run_key',p_run_key,
    'wake_key',p_wake_key
  );
  v_request_hash := md5(v_request::text);

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    raise exception 'graph_runtime_version_mismatch:expected=2,actual=%',
      v_graph.runtime_version using errcode = 'P0001';
  end if;

  select * into v_existing
  from public.control_room_project_graph_wakes_v2
  where graph_run_key = p_run_key
    and wake_key = p_wake_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'wake_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'wake', v_existing.response,
        'idempotent_wake_replay', true
      );
  end if;

  if v_graph.status in ('completed','cancelled') then
    v_response := jsonb_build_object(
      'wake_key',p_wake_key,
      'recovered_nodes','[]'::jsonb,
      'terminal',true
    );

    insert into public.control_room_project_graph_wakes_v2(
      graph_run_key,wake_key,request_hash,response
    ) values (
      p_run_key,p_wake_key,v_request_hash,v_response
    );

    return public.control_room_get_project_graph_runtime_v2(p_run_key)
      || jsonb_build_object(
        'wake',v_response,
        'idempotent_wake_replay',false
      );
  end if;

  for v_node in
    select *
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and status in ('running','verifying')
      and execution_token is not null
      and lease_expires_at is not null
      and lease_expires_at <= clock_timestamp()
    order by node_index, node_key
    for update
  loop
    if v_node.status = 'verifying' then
      v_recovery_mode := 'resume_verification';
      v_to_status := 'verifying';

      update public.control_room_project_graph_nodes_v1
      set
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-verification:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_verification_interrupted',
        'warning',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;

    elsif v_node.recovery_policy = 'retry' then
      if v_node.attempt_count < v_node.max_attempts then
        v_recovery_mode := 'requeue';
        v_to_status := 'ready';

        update public.control_room_project_graph_nodes_v1
        set
          status = 'ready',
          execution_token = null,
          heartbeat_at = null,
          lease_expires_at = null,
          interruption_count = interruption_count + 1,
          last_recovered_at = clock_timestamp(),
          evidence = evidence || jsonb_build_object(
            'last_recovery',
            jsonb_build_object(
              'mode',v_recovery_mode,
              'execution_epoch',v_node.execution_epoch,
              'recovered_at',now()
            )
          ),
          updated_at = now()
        where id = v_node.id;

        v_exception_key := 'stale-requeue:' || v_node.node_key || ':' || v_node.execution_epoch::text;

        insert into public.control_room_project_graph_exceptions_v1(
          graph_run_key,node_id,exception_key,code,severity,status,details,resolved_at,resolution
        ) values (
          p_run_key,
          v_node.id,
          v_exception_key,
          'stale_execution_requeued',
          'info',
          'resolved',
          jsonb_build_object(
            'node_key',v_node.node_key,
            'execution_epoch',v_node.execution_epoch,
            'recovery_mode',v_recovery_mode
          ),
          now(),
          jsonb_build_object('reason','safe_retry_policy')
        )
        on conflict (graph_run_key, exception_key) do nothing;
      else
        v_recovery_mode := 'attempt_budget_exhausted';
        v_to_status := 'failed';

        update public.control_room_project_graph_nodes_v1
        set
          status = 'failed',
          execution_token = null,
          heartbeat_at = null,
          lease_expires_at = null,
          interruption_count = interruption_count + 1,
          last_recovered_at = clock_timestamp(),
          completed_at = now(),
          evidence = evidence || jsonb_build_object(
            'last_recovery',
            jsonb_build_object(
              'mode',v_recovery_mode,
              'execution_epoch',v_node.execution_epoch,
              'recovered_at',now()
            )
          ),
          updated_at = now()
        where id = v_node.id;

        v_exception_key := 'stale-attempt-budget:' || v_node.node_key || ':' || v_node.execution_epoch::text;

        insert into public.control_room_project_graph_exceptions_v1(
          graph_run_key,node_id,exception_key,code,severity,status,details
        ) values (
          p_run_key,
          v_node.id,
          v_exception_key,
          'stale_execution_attempt_budget_exhausted',
          'blocker',
          'open',
          jsonb_build_object(
            'node_key',v_node.node_key,
            'execution_epoch',v_node.execution_epoch,
            'attempt_count',v_node.attempt_count,
            'max_attempts',v_node.max_attempts
          )
        )
        on conflict (graph_run_key, exception_key) do nothing;
      end if;

    elsif v_node.recovery_policy = 'reconcile' then
      v_recovery_mode := 'reconcile';
      v_to_status := 'verifying';

      update public.control_room_project_graph_nodes_v1
      set
        status = 'verifying',
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-reconcile:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_execution_reconcile',
        'material',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'authority_class',v_node.authority_class,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;

    elsif v_node.recovery_policy = 'owner_gate' then
      v_recovery_mode := 'owner_gate';
      v_to_status := 'waiting_owner';

      update public.control_room_project_graph_nodes_v1
      set
        status = 'waiting_owner',
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        wait_context = jsonb_build_object(
          'reason','stale_execution_owner_gate',
          'execution_epoch',v_node.execution_epoch
        ),
        wait_started_at = now(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-owner-gate:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_execution_owner_gate',
        'material',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;

    else
      v_recovery_mode := 'fail_closed';
      v_to_status := 'failed';

      update public.control_room_project_graph_nodes_v1
      set
        status = 'failed',
        execution_token = null,
        heartbeat_at = null,
        lease_expires_at = null,
        interruption_count = interruption_count + 1,
        last_recovered_at = clock_timestamp(),
        completed_at = now(),
        evidence = evidence || jsonb_build_object(
          'last_recovery',
          jsonb_build_object(
            'mode',v_recovery_mode,
            'execution_epoch',v_node.execution_epoch,
            'recovered_at',now()
          )
        ),
        updated_at = now()
      where id = v_node.id;

      v_exception_key := 'stale-fail-closed:' || v_node.node_key || ':' || v_node.execution_epoch::text;

      insert into public.control_room_project_graph_exceptions_v1(
        graph_run_key,node_id,exception_key,code,severity,status,details
      ) values (
        p_run_key,
        v_node.id,
        v_exception_key,
        'stale_execution_failed_closed',
        'blocker',
        'open',
        jsonb_build_object(
          'node_key',v_node.node_key,
          'execution_epoch',v_node.execution_epoch,
          'recovery_mode',v_recovery_mode
        )
      )
      on conflict (graph_run_key, exception_key) do nothing;
    end if;

    v_transition_key := 'wake:' || md5(
      p_wake_key || ':' || v_node.node_key || ':' || v_node.execution_epoch::text
    );

    v_transition_request := jsonb_build_object(
      'kind','wake_recovery',
      'wake_key',p_wake_key,
      'node_key',v_node.node_key,
      'execution_epoch',v_node.execution_epoch,
      'from_status',v_node.status,
      'to_status',v_to_status,
      'recovery_mode',v_recovery_mode
    );

    v_transition_response := jsonb_build_object(
      'node_key',v_node.node_key,
      'from_status',v_node.status,
      'to_status',v_to_status,
      'recovery_mode',v_recovery_mode,
      'execution_epoch',v_node.execution_epoch
    );

    insert into public.control_room_project_graph_node_transitions_v2(
      graph_run_key,
      node_id,
      transition_key,
      request_hash,
      transition_kind,
      from_status,
      to_status,
      phase,
      lease_token,
      request,
      response
    )
    values(
      p_run_key,
      v_node.id,
      v_transition_key,
      md5(v_transition_request::text),
      'wake_recovery',
      v_node.status,
      v_to_status,
      v_recovery_mode,
      v_node.execution_token,
      v_transition_request,
      v_transition_response
    )
    on conflict (graph_run_key, transition_key) do nothing;

    v_recovered := v_recovered || jsonb_build_array(v_transition_response);
  end loop;

  v_runtime := public.control_room_refresh_project_graph_v2(p_run_key);

  v_response := jsonb_build_object(
    'wake_key',p_wake_key,
    'recovered_nodes',v_recovered,
    'recovered_count',jsonb_array_length(v_recovered)
  );

  insert into public.control_room_project_graph_wakes_v2(
    graph_run_key,wake_key,request_hash,response
  )
  values(
    p_run_key,p_wake_key,v_request_hash,v_response
  );

  return v_runtime
    || jsonb_build_object(
      'wake',v_response,
      'idempotent_wake_replay',false
    );
end;
$$;

revoke all on function public.control_room_claim_project_graph_node_v2(text,text,text,integer)
  from public, anon, authenticated;
revoke all on function public.control_room_heartbeat_project_graph_node_v2(text,text,uuid,text,integer)
  from public, anon, authenticated;
revoke all on function public.control_room_transition_project_graph_node_v2(text,text,text,text,text,uuid,jsonb,jsonb,jsonb)
  from public, anon, authenticated;
revoke all on function public.control_room_retry_project_graph_node_v2(text,text,text,jsonb)
  from public, anon, authenticated;
revoke all on function public.control_room_wake_project_graph_v2(text,text)
  from public, anon, authenticated;

grant execute on function public.control_room_claim_project_graph_node_v2(text,text,text,integer) to service_role;
grant execute on function public.control_room_heartbeat_project_graph_node_v2(text,text,uuid,text,integer) to service_role;
grant execute on function public.control_room_transition_project_graph_node_v2(text,text,text,text,text,uuid,jsonb,jsonb,jsonb) to service_role;
grant execute on function public.control_room_retry_project_graph_node_v2(text,text,text,jsonb) to service_role;
grant execute on function public.control_room_wake_project_graph_v2(text,text) to service_role;

commit;
