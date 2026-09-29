begin;

-- PER-2 core persistence. Source-controlled reconstruction of applied migration 20260929075156.

alter table public.control_room_project_graph_runs_v1
  add column if not exists runtime_version smallint not null default 1
    check (runtime_version between 1 and 100);

alter table public.control_room_project_graph_nodes_v1
  add column if not exists recovery_policy text not null default 'retry'
    check (recovery_policy in ('retry','reconcile','owner_gate','fail')),
  add column if not exists execution_token uuid null,
  add column if not exists lease_expires_at timestamptz null,
  add column if not exists heartbeat_at timestamptz null,
  add column if not exists execution_epoch integer not null default 0
    check (execution_epoch >= 0),
  add column if not exists interruption_count integer not null default 0
    check (interruption_count >= 0),
  add column if not exists wait_context jsonb not null default '{}'::jsonb
    check (jsonb_typeof(wait_context) = 'object'),
  add column if not exists wait_started_at timestamptz null,
  add column if not exists last_recovered_at timestamptz null;

create index if not exists control_room_project_graph_nodes_v1_lease_idx
  on public.control_room_project_graph_nodes_v1(graph_run_key, lease_expires_at)
  where status in ('running','verifying');

create table if not exists public.control_room_project_graph_node_transitions_v2 (
  id uuid primary key default gen_random_uuid(),
  graph_run_key text not null
    references public.control_room_project_graph_runs_v1(run_key) on delete cascade,
  node_id uuid not null,
  transition_key text not null check (char_length(transition_key) between 1 and 240),
  request_hash text not null check (request_hash ~ '^[0-9a-f]{32}$'),
  transition_kind text not null
    check (transition_kind in ('claim','heartbeat','state','retry','wake_recovery')),
  from_status text null,
  to_status text null,
  phase text null,
  lease_token uuid null,
  request jsonb not null default '{}'::jsonb check (jsonb_typeof(request) = 'object'),
  response jsonb not null default '{}'::jsonb check (jsonb_typeof(response) = 'object'),
  created_at timestamptz not null default now(),
  foreign key (graph_run_key, node_id)
    references public.control_room_project_graph_nodes_v1(graph_run_key, id)
    on delete cascade,
  unique (graph_run_key, transition_key)
);

create index if not exists control_room_project_graph_node_transitions_v2_node_idx
  on public.control_room_project_graph_node_transitions_v2(graph_run_key, node_id, created_at desc);

create table if not exists public.control_room_project_graph_exceptions_v1 (
  id uuid primary key default gen_random_uuid(),
  graph_run_key text not null
    references public.control_room_project_graph_runs_v1(run_key) on delete cascade,
  node_id uuid null,
  exception_key text not null check (char_length(exception_key) between 1 and 300),
  code text not null check (char_length(code) between 1 and 200),
  severity text not null check (severity in ('info','warning','material','blocker')),
  status text not null default 'open' check (status in ('open','resolved')),
  details jsonb not null default '{}'::jsonb check (jsonb_typeof(details) = 'object'),
  detected_at timestamptz not null default now(),
  resolved_at timestamptz null,
  resolution jsonb null check (resolution is null or jsonb_typeof(resolution) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (graph_run_key, node_id)
    references public.control_room_project_graph_nodes_v1(graph_run_key, id)
    on delete cascade,
  unique (graph_run_key, exception_key)
);

create index if not exists control_room_project_graph_exceptions_v1_open_idx
  on public.control_room_project_graph_exceptions_v1(graph_run_key, status, detected_at desc);

create table if not exists public.control_room_project_graph_wakes_v2 (
  graph_run_key text not null
    references public.control_room_project_graph_runs_v1(run_key) on delete cascade,
  wake_key text not null check (char_length(wake_key) between 1 and 240),
  request_hash text not null check (request_hash ~ '^[0-9a-f]{32}$'),
  response jsonb not null default '{}'::jsonb check (jsonb_typeof(response) = 'object'),
  created_at timestamptz not null default now(),
  primary key (graph_run_key, wake_key)
);

alter table public.control_room_project_graph_node_transitions_v2 enable row level security;
alter table public.control_room_project_graph_exceptions_v1 enable row level security;
alter table public.control_room_project_graph_wakes_v2 enable row level security;

revoke all on public.control_room_project_graph_node_transitions_v2 from public, anon, authenticated;
revoke all on public.control_room_project_graph_exceptions_v1 from public, anon, authenticated;
revoke all on public.control_room_project_graph_wakes_v2 from public, anon, authenticated;

grant select, insert on public.control_room_project_graph_node_transitions_v2 to service_role;
grant select, insert, update on public.control_room_project_graph_exceptions_v1 to service_role;
grant select, insert on public.control_room_project_graph_wakes_v2 to service_role;

CREATE OR REPLACE FUNCTION public.control_room_create_project_work_graph_v2(p_project_key text, p_work_unit_key text, p_run_key text, p_source_state_version integer, p_work_unit jsonb, p_nodes jsonb, p_edges jsonb, p_run_limits jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_base jsonb;
  v_replay boolean;
  v_runtime_version smallint;
  v_node jsonb;
  v_policy text;
begin
  v_base := public.control_room_create_project_work_graph_v1(
    p_project_key,
    p_work_unit_key,
    p_run_key,
    p_source_state_version,
    p_work_unit,
    p_nodes,
    p_edges,
    p_run_limits
  );

  v_replay := coalesce((v_base->>'idempotent_replay')::boolean, false);

  select runtime_version into v_runtime_version
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  if v_replay and v_runtime_version <> 2 then
    raise exception 'graph_runtime_version_conflict:expected=2,actual=%',
      v_runtime_version using errcode = 'P0001';
  end if;

  if not v_replay then
    update public.control_room_project_graph_runs_v1
    set runtime_version = 2,
        compiler_version = coalesce(nullif(p_work_unit->>'compiler_version',''), 'per2'),
        updated_at = now()
    where run_key = p_run_key;

    for v_node in
      select value from jsonb_array_elements(p_nodes)
    loop
      v_policy := nullif(v_node->>'recovery_policy','');

      if v_policy is null then
        v_policy := case
          when coalesce(v_node->>'execution_mode','server_executable') = 'human_gate'
            or coalesce(v_node->>'authority_class','read_only') = 'owner_gate'
            then 'owner_gate'
          when coalesce(v_node->>'authority_class','read_only') in ('bounded_write','external_write')
            then 'reconcile'
          else 'retry'
        end;
      end if;

      if v_policy not in ('retry','reconcile','owner_gate','fail') then
        raise exception 'invalid_recovery_policy:%', v_policy using errcode = 'P0001';
      end if;

      update public.control_room_project_graph_nodes_v1
      set recovery_policy = v_policy,
          updated_at = now()
      where graph_run_key = p_run_key
        and node_key = v_node->>'node_key';
    end loop;
  end if;

  return public.control_room_refresh_project_graph_v2(p_run_key)
    || jsonb_build_object('idempotent_replay', v_replay);
end;
$$;

CREATE OR REPLACE FUNCTION public.control_room_get_project_graph_runtime_v2(p_run_key text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
  select public.control_room_get_project_work_graph_v1(p_run_key)
    || jsonb_build_object(
      'runtime',
      jsonb_build_object(
        'runtime_version', g.runtime_version,
        'stale_active_nodes', (
          select count(*)
          from public.control_room_project_graph_nodes_v1 n
          where n.graph_run_key = g.run_key
            and n.status in ('running','verifying')
            and n.execution_token is not null
            and n.lease_expires_at is not null
            and n.lease_expires_at <= clock_timestamp()
        ),
        'open_exception_count', (
          select count(*)
          from public.control_room_project_graph_exceptions_v1 x
          where x.graph_run_key = g.run_key
            and x.status = 'open'
        ),
        'transition_count', (
          select count(*)
          from public.control_room_project_graph_node_transitions_v2 t
          where t.graph_run_key = g.run_key
        )
      ),
      'exceptions',
      coalesce((
        select jsonb_agg(to_jsonb(x) order by x.detected_at, x.exception_key)
        from public.control_room_project_graph_exceptions_v1 x
        where x.graph_run_key = g.run_key
      ), '[]'::jsonb)
    )
  from public.control_room_project_graph_runs_v1 g
  where g.run_key = p_run_key
$$;

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

revoke all on function public.control_room_get_project_graph_runtime_v2(text)
  from public, anon, authenticated;
revoke all on function public.control_room_refresh_project_graph_v2(text)
  from public, anon, authenticated;
revoke all on function public.control_room_create_project_work_graph_v2(text,text,text,integer,jsonb,jsonb,jsonb,jsonb)
  from public, anon, authenticated;

grant execute on function public.control_room_get_project_graph_runtime_v2(text) to service_role;
grant execute on function public.control_room_refresh_project_graph_v2(text) to service_role;
grant execute on function public.control_room_create_project_work_graph_v2(text,text,text,integer,jsonb,jsonb,jsonb,jsonb) to service_role;

commit;
