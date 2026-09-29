-- PER-2 durable wait-context backfill.

CREATE OR REPLACE FUNCTION public.control_room_refresh_project_graph_v2(p_run_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_envelope public.control_room_run_envelopes%rowtype;
  v_action_space jsonb := '[]'::jsonb;
  v_resume_from text;
  v_status text;
  v_envelope_status text;
  v_stop_reason text;
  v_total integer;
  v_success_terminal integer;
  v_cancelled integer;
  v_plain_stop_failed integer;
  v_attempt_exhausted integer;
  v_retry_budget_exhausted integer;
  v_ready integer;
  v_running_live integer;
  v_verifying_live integer;
  v_verifying_resumable integer;
  v_stale_active integer;
  v_waiting_session integer;
  v_waiting_owner integer;
  v_retry_available integer;
  v_action_budget_exhausted boolean := false;
begin
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

  select * into v_envelope
  from public.control_room_run_envelopes
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'run_envelope_not_found' using errcode = 'P0001';
  end if;

  update public.control_room_project_graph_nodes_v1 n
  set
    status = case
      when not exists (
        select 1
        from public.control_room_project_graph_edges_v1 e
        join public.control_room_project_graph_nodes_v1 src
          on src.graph_run_key = e.graph_run_key
         and src.id = e.from_node_id
        where e.graph_run_key = p_run_key
          and e.to_node_id = n.id
          and not (
            (e.required_status = 'completed' and src.status = 'completed')
            or (e.required_status = 'failed' and src.status = 'failed')
            or (e.required_status = 'terminal' and src.status in ('completed','failed','skipped','cancelled'))
          )
      )
      then case n.execution_mode
        when 'human_gate' then 'waiting_owner'
        when 'chatgpt_session' then 'waiting_session'
        else 'ready'
      end
      else 'waiting_dependency'
    end,
    wait_context = case
      when not exists (
        select 1
        from public.control_room_project_graph_edges_v1 e
        join public.control_room_project_graph_nodes_v1 src
          on src.graph_run_key = e.graph_run_key
         and src.id = e.from_node_id
        where e.graph_run_key = p_run_key
          and e.to_node_id = n.id
          and not (
            (e.required_status = 'completed' and src.status = 'completed')
            or (e.required_status = 'failed' and src.status = 'failed')
            or (e.required_status = 'terminal' and src.status in ('completed','failed','skipped','cancelled'))
          )
      ) and n.execution_mode = 'human_gate'
        then jsonb_build_object('reason','owner_gate_required')
      when not exists (
        select 1
        from public.control_room_project_graph_edges_v1 e
        join public.control_room_project_graph_nodes_v1 src
          on src.graph_run_key = e.graph_run_key
         and src.id = e.from_node_id
        where e.graph_run_key = p_run_key
          and e.to_node_id = n.id
          and not (
            (e.required_status = 'completed' and src.status = 'completed')
            or (e.required_status = 'failed' and src.status = 'failed')
            or (e.required_status = 'terminal' and src.status in ('completed','failed','skipped','cancelled'))
          )
      ) and n.execution_mode = 'chatgpt_session'
        then jsonb_build_object('reason','chatgpt_session_required')
      else '{}'::jsonb
    end,
    wait_started_at = case
      when not exists (
        select 1
        from public.control_room_project_graph_edges_v1 e
        join public.control_room_project_graph_nodes_v1 src
          on src.graph_run_key = e.graph_run_key
         and src.id = e.from_node_id
        where e.graph_run_key = p_run_key
          and e.to_node_id = n.id
          and not (
            (e.required_status = 'completed' and src.status = 'completed')
            or (e.required_status = 'failed' and src.status = 'failed')
            or (e.required_status = 'terminal' and src.status in ('completed','failed','skipped','cancelled'))
          )
      ) and n.execution_mode in ('human_gate','chatgpt_session')
        then coalesce(n.wait_started_at, now())
      else null
    end,
    updated_at = now()
  where n.graph_run_key = p_run_key
    and n.status in ('pending','waiting_dependency');

  update public.control_room_project_graph_nodes_v1
  set
    wait_context = case
      when status = 'waiting_session' and wait_context = '{}'::jsonb
        then jsonb_build_object('reason','chatgpt_session_required')
      when status = 'waiting_owner' and wait_context = '{}'::jsonb
        then jsonb_build_object('reason','owner_gate_required')
      else wait_context
    end,
    wait_started_at = coalesce(wait_started_at, clock_timestamp()),
    updated_at = now()
  where graph_run_key = p_run_key
    and status in ('waiting_session','waiting_owner');

  select
    count(*),
    count(*) filter (where n.status in ('completed','skipped')),
    count(*) filter (where n.status = 'cancelled'),
    count(*) filter (
      where n.status = 'failed'
        and n.failure_policy = 'stop'
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    ),
    count(*) filter (
      where n.status = 'failed'
        and n.failure_policy in ('retry','repair','fallback')
        and n.attempt_count >= n.max_attempts
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    ),
    count(*) filter (
      where n.status = 'failed'
        and n.failure_policy in ('retry','repair','fallback')
        and n.attempt_count < n.max_attempts
        and v_envelope.max_retries is not null
        and v_envelope.retries_used >= v_envelope.max_retries
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    ),
    count(*) filter (where n.status = 'ready'),
    count(*) filter (
      where n.status = 'running'
        and n.execution_token is not null
        and n.lease_expires_at is not null
        and n.lease_expires_at > clock_timestamp()
    ),
    count(*) filter (
      where n.status = 'verifying'
        and n.execution_token is not null
        and n.lease_expires_at is not null
        and n.lease_expires_at > clock_timestamp()
    ),
    count(*) filter (
      where n.status = 'verifying'
        and n.execution_token is null
    ),
    count(*) filter (
      where n.status in ('running','verifying')
        and n.execution_token is not null
        and n.lease_expires_at is not null
        and n.lease_expires_at <= clock_timestamp()
    ),
    count(*) filter (where n.status = 'waiting_session'),
    count(*) filter (where n.status = 'waiting_owner'),
    count(*) filter (
      where n.status = 'failed'
        and n.failure_policy in ('retry','repair','fallback')
        and n.attempt_count < n.max_attempts
        and (v_envelope.max_retries is null or v_envelope.retries_used < v_envelope.max_retries)
        and not exists (
          select 1 from public.control_room_project_graph_edges_v1 e
          where e.graph_run_key = p_run_key
            and e.from_node_id = n.id
            and e.required_status in ('failed','terminal')
        )
    )
  into
    v_total, v_success_terminal, v_cancelled, v_plain_stop_failed,
    v_attempt_exhausted, v_retry_budget_exhausted, v_ready,
    v_running_live, v_verifying_live, v_verifying_resumable,
    v_stale_active, v_waiting_session, v_waiting_owner, v_retry_available
  from public.control_room_project_graph_nodes_v1 n
  where n.graph_run_key = p_run_key;

  if v_total = 0 then
    raise exception 'graph_requires_nodes' using errcode = 'P0001';
  end if;

  v_action_budget_exhausted :=
    v_ready > 0
    and v_envelope.max_actions is not null
    and v_envelope.actions_used >= v_envelope.max_actions;

  if v_plain_stop_failed > 0 then
    v_status := 'failed';
    v_stop_reason := 'graph_failed';
  elsif v_attempt_exhausted > 0 then
    v_status := 'failed';
    v_stop_reason := 'node_attempt_budget_exhausted';
  elsif v_retry_budget_exhausted > 0 then
    v_status := 'failed';
    v_stop_reason := 'retry_budget_exhausted';
  elsif v_action_budget_exhausted then
    v_status := 'failed';
    v_stop_reason := 'action_budget_exhausted';
  elsif v_stale_active > 0 then
    v_status := 'waiting';
    v_stop_reason := 'stale_execution_wake_required';
  elsif v_success_terminal = v_total then
    v_status := 'completed';
    v_stop_reason := null;
  elsif v_success_terminal + v_cancelled = v_total and v_cancelled > 0 then
    v_status := 'cancelled';
    v_stop_reason := 'graph_cancelled';
  elsif v_ready + v_running_live + v_verifying_live + v_verifying_resumable > 0 then
    v_status := 'active';
    v_stop_reason := null;
  elsif v_retry_available > 0 then
    v_status := 'waiting';
    v_stop_reason := 'retry_available';
  else
    v_status := 'waiting';
    v_stop_reason := case
      when v_waiting_owner > 0 then 'waiting_owner'
      when v_waiting_session > 0 then 'waiting_session'
      else 'dependency_wait'
    end;
  end if;

  if v_status = 'active' then
    select coalesce(
      jsonb_agg(item order by ord, node_key),
      '[]'::jsonb
    )
    into v_action_space
    from (
      select
        n.node_index as ord,
        n.node_key,
        jsonb_build_object(
          'node_key', n.node_key,
          'node_type', n.node_type,
          'execution_mode', n.execution_mode,
          'required_capability', n.required_capability,
          'authority_class', n.authority_class,
          'resume_phase', 'execute'
        ) as item
      from public.control_room_project_graph_nodes_v1 n
      where n.graph_run_key = p_run_key
        and n.status = 'ready'

      union all

      select
        n.node_index as ord,
        n.node_key,
        jsonb_build_object(
          'node_key', n.node_key,
          'node_type', n.node_type,
          'execution_mode', n.execution_mode,
          'required_capability', n.required_capability,
          'authority_class', n.authority_class,
          'resume_phase',
          case when n.recovery_policy = 'reconcile' then 'reconcile' else 'verify' end
        ) as item
      from public.control_room_project_graph_nodes_v1 n
      where n.graph_run_key = p_run_key
        and n.status = 'verifying'
        and n.execution_token is null
    ) q;
  end if;

  v_resume_from := null;

  if v_status = 'active' then
    select node_key into v_resume_from
    from (
      select n.node_key, n.node_index, 0 as phase_order
      from public.control_room_project_graph_nodes_v1 n
      where n.graph_run_key = p_run_key and n.status = 'ready'
      union all
      select n.node_key, n.node_index, 1 as phase_order
      from public.control_room_project_graph_nodes_v1 n
      where n.graph_run_key = p_run_key
        and n.status = 'verifying'
        and n.execution_token is null
    ) q
    order by node_index, phase_order, node_key
    limit 1;
  elsif v_status = 'waiting' and v_stop_reason = 'retry_available' then
    select n.node_key into v_resume_from
    from public.control_room_project_graph_nodes_v1 n
    where n.graph_run_key = p_run_key
      and n.status = 'failed'
      and n.failure_policy in ('retry','repair','fallback')
      and n.attempt_count < n.max_attempts
      and (v_envelope.max_retries is null or v_envelope.retries_used < v_envelope.max_retries)
    order by n.node_index, n.node_key
    limit 1;
  elsif v_status = 'waiting' and v_stop_reason in ('waiting_session','waiting_owner') then
    select n.node_key into v_resume_from
    from public.control_room_project_graph_nodes_v1 n
    where n.graph_run_key = p_run_key
      and n.status in ('waiting_session','waiting_owner')
    order by
      case n.status when 'waiting_session' then 0 else 1 end,
      n.node_index,
      n.node_key
    limit 1;
  end if;

  update public.control_room_project_graph_runs_v1
  set
    status = v_status,
    started_at = coalesce(started_at, case when v_status <> 'planned' then now() else null end),
    completed_at = case
      when v_status in ('completed','failed','cancelled') then coalesce(completed_at, now())
      else null
    end,
    updated_at = now()
  where run_key = p_run_key;

  update public.control_room_project_work_units_v1
  set
    status = case v_status
      when 'active' then 'active'
      when 'waiting' then 'waiting'
      when 'completed' then 'completed'
      when 'failed' then 'failed'
      when 'cancelled' then 'cancelled'
      else status
    end,
    completed_at = case
      when v_status in ('completed','failed','cancelled') then coalesce(completed_at, now())
      else null
    end,
    updated_at = now()
  where id = v_graph.work_unit_id;

  v_envelope_status := case v_status
    when 'active' then 'active'
    when 'waiting' then 'paused'
    when 'completed' then 'completed'
    when 'failed' then 'blocked'
    when 'cancelled' then 'paused'
    else 'active'
  end;

  update public.control_room_run_envelopes
  set
    status = v_envelope_status,
    action_space = v_action_space,
    resume_from = v_resume_from,
    stop_reason = v_stop_reason,
    updated_at = now()
  where run_key = p_run_key;

  return public.control_room_get_project_graph_runtime_v2(p_run_key);
end;
$$;
