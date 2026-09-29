begin;

create table if not exists public.control_room_execution_executors_v1 (
  executor_key text primary key
    check (executor_key ~ '^[a-z0-9][a-z0-9._-]{1,199}$'),
  executor_kind text not null
    check (executor_kind in ('builtin')),
  status text not null default 'active'
    check (status in ('active','disabled')),
  description text not null
    check (char_length(description) between 1 and 5000),
  max_authority_class text not null default 'read_only'
    check (max_authority_class in ('read_only','prepare','bounded_write','external_write')),
  supported_execution_modes text[] not null
    check (
      cardinality(supported_execution_modes) > 0
      and supported_execution_modes <@ array['server_executable','deterministic_code']::text[]
    ),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.control_room_execution_capabilities_v1 (
  capability_key text primary key
    check (capability_key ~ '^[a-z0-9][a-z0-9._-]{1,199}$'),
  executor_key text not null
    references public.control_room_execution_executors_v1(executor_key)
    on update cascade on delete restrict,
  status text not null default 'active'
    check (status in ('active','disabled')),
  description text not null
    check (char_length(description) between 1 and 5000),
  max_authority_class text not null default 'read_only'
    check (max_authority_class in ('read_only','prepare','bounded_write','external_write')),
  supported_execution_modes text[] not null
    check (
      cardinality(supported_execution_modes) > 0
      and supported_execution_modes <@ array['server_executable','deterministic_code']::text[]
    ),
  supported_phases text[] not null default array['execute']::text[]
    check (
      cardinality(supported_phases) > 0
      and supported_phases <@ array['execute','verify','reconcile']::text[]
    ),
  input_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(input_contract) = 'object'),
  output_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(output_contract) = 'object'),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists control_room_execution_capabilities_v1_executor_idx
  on public.control_room_execution_capabilities_v1(executor_key);

create table if not exists public.control_room_project_capability_bindings_v1 (
  project_id uuid not null
    references public.control_room_projects(id) on delete cascade,
  capability_key text not null
    references public.control_room_execution_capabilities_v1(capability_key)
    on update cascade on delete cascade,
  status text not null default 'active'
    check (status in ('active','disabled')),
  max_authority_class text not null default 'read_only'
    check (max_authority_class in ('read_only','prepare','bounded_write','external_write')),
  config jsonb not null default '{}'::jsonb
    check (jsonb_typeof(config) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (project_id, capability_key)
);

create index if not exists control_room_project_capability_bindings_v1_capability_idx
  on public.control_room_project_capability_bindings_v1(capability_key);

create table if not exists public.control_room_project_graph_dispatches_v1 (
  id uuid primary key default gen_random_uuid(),
  graph_run_key text not null
    references public.control_room_project_graph_runs_v1(run_key) on delete cascade,
  node_id uuid not null,
  project_id uuid not null
    references public.control_room_projects(id) on delete cascade,
  dispatch_key text not null
    check (char_length(dispatch_key) between 1 and 240),
  request_hash text not null
    check (request_hash ~ '^[0-9a-f]{32}$'),
  requested_capability text null,
  resolved_capability text null
    references public.control_room_execution_capabilities_v1(capability_key)
    on update cascade on delete restrict,
  executor_key text null
    references public.control_room_execution_executors_v1(executor_key)
    on update cascade on delete restrict,
  phase text null
    check (phase is null or phase in ('execute','verify','reconcile')),
  authority_class text not null
    check (authority_class in ('read_only','prepare','bounded_write','external_write','owner_gate')),
  execution_mode text not null
    check (execution_mode in ('server_executable','chatgpt_session','human_gate','deterministic_code')),
  status text not null
    check (status in ('planned','executing','completed','failed','rejected','waiting')),
  input jsonb not null default '{}'::jsonb
    check (jsonb_typeof(input) = 'object'),
  result jsonb null
    check (result is null or jsonb_typeof(result) = 'object'),
  evidence jsonb not null default '{}'::jsonb
    check (jsonb_typeof(evidence) = 'object'),
  response jsonb not null default '{}'::jsonb
    check (jsonb_typeof(response) = 'object'),
  error_code text null,
  created_at timestamptz not null default now(),
  started_at timestamptz null,
  completed_at timestamptz null,
  updated_at timestamptz not null default now(),
  foreign key (graph_run_key, node_id)
    references public.control_room_project_graph_nodes_v1(graph_run_key, id)
    on delete cascade,
  unique (graph_run_key, dispatch_key)
);

create index if not exists control_room_project_graph_dispatches_v1_node_idx
  on public.control_room_project_graph_dispatches_v1(graph_run_key, node_id, created_at desc);

create index if not exists control_room_project_graph_dispatches_v1_project_idx
  on public.control_room_project_graph_dispatches_v1(project_id, created_at desc);

create index if not exists control_room_project_graph_dispatches_v1_capability_idx
  on public.control_room_project_graph_dispatches_v1(resolved_capability)
  where resolved_capability is not null;

create index if not exists control_room_project_graph_dispatches_v1_executor_idx
  on public.control_room_project_graph_dispatches_v1(executor_key)
  where executor_key is not null;

alter table public.control_room_execution_executors_v1 enable row level security;
alter table public.control_room_execution_capabilities_v1 enable row level security;
alter table public.control_room_project_capability_bindings_v1 enable row level security;
alter table public.control_room_project_graph_dispatches_v1 enable row level security;

revoke all on public.control_room_execution_executors_v1 from public, anon, authenticated, service_role;
revoke all on public.control_room_execution_capabilities_v1 from public, anon, authenticated, service_role;
revoke all on public.control_room_project_capability_bindings_v1 from public, anon, authenticated, service_role;
revoke all on public.control_room_project_graph_dispatches_v1 from public, anon, authenticated, service_role;

grant select on public.control_room_execution_executors_v1 to service_role;
grant select on public.control_room_execution_capabilities_v1 to service_role;
grant select on public.control_room_project_capability_bindings_v1 to service_role;
grant select, insert, update on public.control_room_project_graph_dispatches_v1 to service_role;

create or replace function public.control_room_execution_authority_rank_v1(
  p_authority_class text
)
returns smallint
language sql
immutable
security invoker
set search_path = public, pg_temp
as $$
  select case p_authority_class
    when 'read_only' then 0::smallint
    when 'prepare' then 1::smallint
    when 'bounded_write' then 2::smallint
    when 'external_write' then 3::smallint
    when 'owner_gate' then 4::smallint
    else null::smallint
  end
$$;

create or replace function public.control_room_resolve_project_graph_dispatch_v1(
  p_run_key text,
  p_node_key text
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_envelope public.control_room_run_envelopes%rowtype;
  v_project public.control_room_projects%rowtype;
  v_cap public.control_room_execution_capabilities_v1%rowtype;
  v_binding public.control_room_project_capability_bindings_v1%rowtype;
  v_executor public.control_room_execution_executors_v1%rowtype;
  v_phase text;
  v_node_rank smallint;
  v_cap_rank smallint;
  v_binding_rank smallint;
  v_executor_rank smallint;
begin
  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  select * into v_envelope
  from public.control_room_run_envelopes
  where run_key = p_run_key;

  if not found then
    raise exception 'run_envelope_not_found' using errcode = 'P0001';
  end if;

  select * into v_project
  from public.control_room_projects
  where id = v_graph.project_id;

  if not found then
    raise exception 'project_not_found' using errcode = 'P0001';
  end if;

  if v_graph.runtime_version <> 2 then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','runtime_version_unsupported',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'runtime_version',v_graph.runtime_version
    );
  end if;

  if v_graph.status in ('completed','failed','cancelled') then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','graph_not_active',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'graph_status',v_graph.status
    );
  end if;

  if v_node.status = 'waiting_session'
     or v_node.execution_mode = 'chatgpt_session' then
    return jsonb_build_object(
      'route_status','waiting_session',
      'error_code','chatgpt_session_required',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'execution_mode',v_node.execution_mode,
      'authority_class',v_node.authority_class,
      'required_capability',v_node.required_capability
    );
  end if;

  if v_node.status = 'waiting_owner'
     or v_node.execution_mode = 'human_gate'
     or v_node.authority_class = 'owner_gate' then
    return jsonb_build_object(
      'route_status','waiting_owner',
      'error_code','owner_gate_required',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'execution_mode',v_node.execution_mode,
      'authority_class',v_node.authority_class,
      'required_capability',v_node.required_capability
    );
  end if;

  if v_node.status = 'ready' then
    v_phase := 'execute';
  elsif v_node.status = 'verifying' and v_node.execution_token is null then
    v_phase := case
      when v_node.recovery_policy = 'reconcile' then 'reconcile'
      else 'verify'
    end;
  else
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','node_not_dispatchable',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'node_status',v_node.status,
      'execution_token_present',(v_node.execution_token is not null)
    );
  end if;

  if v_envelope.status <> 'active' then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','run_envelope_not_active',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'run_status',v_envelope.status,
      'phase',v_phase
    );
  end if;

  if v_phase = 'execute'
     and v_envelope.max_actions is not null
     and v_envelope.actions_used >= v_envelope.max_actions then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','action_budget_exhausted',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'phase',v_phase,
      'actions_used',v_envelope.actions_used,
      'max_actions',v_envelope.max_actions
    );
  end if;

  if v_node.required_capability is null then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','capability_required',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase
    );
  end if;

  select * into v_cap
  from public.control_room_execution_capabilities_v1
  where capability_key = v_node.required_capability;

  if not found then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','capability_not_registered',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability
    );
  end if;

  if v_cap.status <> 'active' then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','capability_disabled',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability
    );
  end if;

  select * into v_binding
  from public.control_room_project_capability_bindings_v1
  where project_id = v_graph.project_id
    and capability_key = v_cap.capability_key;

  if not found then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','capability_not_bound',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability
    );
  end if;

  if v_binding.status <> 'active' then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','capability_binding_disabled',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability
    );
  end if;

  select * into v_executor
  from public.control_room_execution_executors_v1
  where executor_key = v_cap.executor_key;

  if not found then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','executor_not_registered',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability,
      'executor_key',v_cap.executor_key
    );
  end if;

  if v_executor.status <> 'active' then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','executor_disabled',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability,
      'executor_key',v_executor.executor_key
    );
  end if;

  if not (v_node.execution_mode = any(v_cap.supported_execution_modes))
     or not (v_node.execution_mode = any(v_executor.supported_execution_modes)) then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','execution_mode_not_supported',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'execution_mode',v_node.execution_mode,
      'required_capability',v_node.required_capability,
      'executor_key',v_executor.executor_key
    );
  end if;

  if not (v_phase = any(v_cap.supported_phases)) then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','dispatch_phase_not_supported',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'required_capability',v_node.required_capability,
      'executor_key',v_executor.executor_key
    );
  end if;

  v_node_rank := public.control_room_execution_authority_rank_v1(v_node.authority_class);
  v_cap_rank := public.control_room_execution_authority_rank_v1(v_cap.max_authority_class);
  v_binding_rank := public.control_room_execution_authority_rank_v1(v_binding.max_authority_class);
  v_executor_rank := public.control_room_execution_authority_rank_v1(v_executor.max_authority_class);

  if v_node_rank is null
     or v_cap_rank is null
     or v_binding_rank is null
     or v_executor_rank is null then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','authority_configuration_invalid',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'phase',v_phase
    );
  end if;

  if v_node_rank > v_cap_rank then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','capability_authority_exceeded',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'authority_class',v_node.authority_class,
      'capability_max_authority',v_cap.max_authority_class,
      'required_capability',v_cap.capability_key
    );
  end if;

  if v_node_rank > v_binding_rank then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','project_binding_authority_exceeded',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'authority_class',v_node.authority_class,
      'binding_max_authority',v_binding.max_authority_class,
      'required_capability',v_cap.capability_key
    );
  end if;

  if v_node_rank > v_executor_rank then
    return jsonb_build_object(
      'route_status','rejected',
      'error_code','executor_authority_exceeded',
      'run_key',p_run_key,
      'node_key',p_node_key,
      'project_key',v_project.project_key,
      'phase',v_phase,
      'authority_class',v_node.authority_class,
      'executor_max_authority',v_executor.max_authority_class,
      'executor_key',v_executor.executor_key
    );
  end if;

  return jsonb_build_object(
    'route_status','dispatchable',
    'error_code',null,
    'run_key',p_run_key,
    'node_key',p_node_key,
    'node_id',v_node.id,
    'project_id',v_graph.project_id,
    'project_key',v_project.project_key,
    'phase',v_phase,
    'execution_mode',v_node.execution_mode,
    'authority_class',v_node.authority_class,
    'required_capability',v_cap.capability_key,
    'executor_key',v_executor.executor_key,
    'executor_kind',v_executor.executor_kind,
    'actions_used',v_envelope.actions_used,
    'max_actions',v_envelope.max_actions
  );
end;
$$;

create or replace function public.control_room_execute_builtin_capability_v1(
  p_executor_key text,
  p_project_id uuid,
  p_input jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_project_key text;
  v_state jsonb;
begin
  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    raise exception 'input_object_required' using errcode = 'P0001';
  end if;

  if p_executor_key = 'control_room.project_state.read.v1' then
    select project_key into v_project_key
    from public.control_room_projects
    where id = p_project_id;

    if not found then
      raise exception 'project_not_found' using errcode = 'P0001';
    end if;

    v_state := public.control_room_get_project_state_v3(v_project_key);

    return jsonb_build_object(
      'project_key',v_project_key,
      'project_state',v_state,
      'observed_at',clock_timestamp()
    );
  end if;

  raise exception 'builtin_executor_not_supported:%', p_executor_key using errcode = 'P0001';
end;
$$;

create or replace function public.control_room_get_project_dispatch_runtime_v1(
  p_run_key text
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select public.control_room_get_project_graph_runtime_v2(p_run_key)
    || jsonb_build_object(
      'dispatch_runtime',
      jsonb_build_object(
        'dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
        ),
        'completed_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.status = 'completed'
        ),
        'failed_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.status = 'failed'
        ),
        'rejected_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.status = 'rejected'
        ),
        'waiting_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.status = 'waiting'
        )
      ),
      'dispatches',
      coalesce((
        select jsonb_agg(to_jsonb(d) order by d.created_at, d.dispatch_key)
        from public.control_room_project_graph_dispatches_v1 d
        where d.graph_run_key = p_run_key
      ), '[]'::jsonb)
    )
$$;

create or replace function public.control_room_dispatch_project_graph_node_v1(
  p_run_key text,
  p_node_key text,
  p_dispatch_key text,
  p_input jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_existing public.control_room_project_graph_dispatches_v1%rowtype;
  v_route jsonb;
  v_request jsonb;
  v_request_hash text;
  v_dispatch_status text;
  v_claim jsonb;
  v_lease_token uuid;
  v_phase text;
  v_result jsonb;
  v_evidence jsonb;
  v_response jsonb;
  v_runtime jsonb;
  v_error_state text;
  v_error_message text;
begin
  if p_dispatch_key is null
     or btrim(p_dispatch_key) = ''
     or char_length(p_dispatch_key) > 240 then
    raise exception 'invalid_dispatch_key' using errcode = 'P0001';
  end if;

  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    raise exception 'input_object_required' using errcode = 'P0001';
  end if;

  v_request := jsonb_build_object(
    'run_key',p_run_key,
    'node_key',p_node_key,
    'input',p_input
  );
  v_request_hash := md5(v_request::text);

  perform pg_advisory_xact_lock(hashtextextended(p_run_key || ':' || p_dispatch_key, 0));

  select * into v_existing
  from public.control_room_project_graph_dispatches_v1
  where graph_run_key = p_run_key
    and dispatch_key = p_dispatch_key;

  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'dispatch_key_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
      || jsonb_build_object(
        'dispatch',v_existing.response,
        'idempotent_dispatch_replay',true
      );
  end if;

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and node_key = p_node_key
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode = 'P0001';
  end if;

  v_route := public.control_room_resolve_project_graph_dispatch_v1(
    p_run_key,
    p_node_key
  );

  if v_route->>'route_status' <> 'dispatchable' then
    v_dispatch_status := case
      when v_route->>'route_status' in ('waiting_session','waiting_owner')
        then 'waiting'
      else 'rejected'
    end;

    v_response := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'status',v_dispatch_status,
      'route',v_route
    );

    insert into public.control_room_project_graph_dispatches_v1(
      graph_run_key,
      node_id,
      project_id,
      dispatch_key,
      request_hash,
      requested_capability,
      resolved_capability,
      executor_key,
      phase,
      authority_class,
      execution_mode,
      status,
      input,
      evidence,
      response,
      error_code,
      completed_at
    )
    values(
      p_run_key,
      v_node.id,
      v_graph.project_id,
      p_dispatch_key,
      v_request_hash,
      v_node.required_capability,
      case
        when v_route ? 'required_capability'
          and v_route->>'required_capability' = v_node.required_capability
          and exists (
            select 1
            from public.control_room_execution_capabilities_v1 c
            where c.capability_key = v_node.required_capability
          )
        then v_node.required_capability
        else null
      end,
      nullif(v_route->>'executor_key',''),
      nullif(v_route->>'phase',''),
      v_node.authority_class,
      v_node.execution_mode,
      v_dispatch_status,
      p_input,
      jsonb_build_object('preflight',v_route),
      v_response,
      nullif(v_route->>'error_code',''),
      clock_timestamp()
    );

    return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
      || jsonb_build_object(
        'dispatch',v_response,
        'idempotent_dispatch_replay',false
      );
  end if;

  v_phase := v_route->>'phase';

  insert into public.control_room_project_graph_dispatches_v1(
    graph_run_key,
    node_id,
    project_id,
    dispatch_key,
    request_hash,
    requested_capability,
    resolved_capability,
    executor_key,
    phase,
    authority_class,
    execution_mode,
    status,
    input,
    evidence,
    response
  )
  values(
    p_run_key,
    v_node.id,
    v_graph.project_id,
    p_dispatch_key,
    v_request_hash,
    v_node.required_capability,
    v_route->>'required_capability',
    v_route->>'executor_key',
    v_phase,
    v_node.authority_class,
    v_node.execution_mode,
    'planned',
    p_input,
    jsonb_build_object('preflight',v_route),
    '{}'::jsonb
  );

  v_claim := public.control_room_claim_project_graph_node_v2(
    p_run_key,
    p_node_key,
    'per3-dispatch:' || p_dispatch_key || ':claim',
    null
  );

  if v_claim->'claim'->>'phase' <> v_phase then
    raise exception 'dispatch_phase_changed:expected=%,actual=%',
      v_phase, v_claim->'claim'->>'phase'
      using errcode = 'P0001';
  end if;

  v_lease_token := (v_claim->'claim'->>'lease_token')::uuid;

  update public.control_room_project_graph_dispatches_v1
  set
    status = 'executing',
    started_at = clock_timestamp(),
    updated_at = now()
  where graph_run_key = p_run_key
    and dispatch_key = p_dispatch_key;

  begin
    if v_route->>'executor_kind' <> 'builtin' then
      raise exception 'executor_kind_not_supported:%', v_route->>'executor_kind'
        using errcode = 'P0001';
    end if;

    v_result := public.control_room_execute_builtin_capability_v1(
      v_route->>'executor_key',
      v_graph.project_id,
      p_input
    );

    v_evidence := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'capability_key',v_route->>'required_capability',
      'executor_key',v_route->>'executor_key',
      'phase',v_phase,
      'dispatched_at',clock_timestamp()
    );

    if v_phase = 'execute' then
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,
        p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':complete',
        'running',
        'completed',
        v_lease_token,
        v_result,
        jsonb_build_object('dispatch',v_evidence),
        '{}'::jsonb
      );
    else
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,
        p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':complete',
        'verifying',
        'completed',
        v_lease_token,
        v_result,
        jsonb_build_object('dispatch',v_evidence),
        '{}'::jsonb
      );
    end if;

    v_response := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'status','completed',
      'route',v_route,
      'result',v_result,
      'evidence',v_evidence
    );

    update public.control_room_project_graph_dispatches_v1
    set
      status = 'completed',
      result = v_result,
      evidence = evidence || jsonb_build_object('execution',v_evidence),
      response = v_response,
      completed_at = clock_timestamp(),
      updated_at = now()
    where graph_run_key = p_run_key
      and dispatch_key = p_dispatch_key;

  exception when others then
    get stacked diagnostics
      v_error_state = returned_sqlstate,
      v_error_message = message_text;

    v_evidence := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'capability_key',v_route->>'required_capability',
      'executor_key',v_route->>'executor_key',
      'phase',v_phase,
      'error_sqlstate',v_error_state,
      'error_message',v_error_message
    );

    if v_phase = 'execute' then
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,
        p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':failed',
        'running',
        'failed',
        v_lease_token,
        jsonb_build_object(
          'error_code','executor_failed',
          'sqlstate',v_error_state,
          'message',v_error_message
        ),
        jsonb_build_object('dispatch',v_evidence),
        '{}'::jsonb
      );
    else
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,
        p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':failed',
        'verifying',
        'failed',
        v_lease_token,
        jsonb_build_object(
          'error_code','executor_failed',
          'sqlstate',v_error_state,
          'message',v_error_message
        ),
        jsonb_build_object('dispatch',v_evidence),
        '{}'::jsonb
      );
    end if;

    v_response := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'status','failed',
      'route',v_route,
      'error_code','executor_failed',
      'sqlstate',v_error_state,
      'message',v_error_message,
      'evidence',v_evidence
    );

    update public.control_room_project_graph_dispatches_v1
    set
      status = 'failed',
      result = jsonb_build_object(
        'error_code','executor_failed',
        'sqlstate',v_error_state,
        'message',v_error_message
      ),
      evidence = evidence || jsonb_build_object('execution',v_evidence),
      response = v_response,
      error_code = 'executor_failed',
      completed_at = clock_timestamp(),
      updated_at = now()
    where graph_run_key = p_run_key
      and dispatch_key = p_dispatch_key;
  end;

  v_runtime := public.control_room_get_project_dispatch_runtime_v1(p_run_key);

  return v_runtime
    || jsonb_build_object(
      'dispatch',v_response,
      'idempotent_dispatch_replay',false
    );
end;
$$;

revoke all on function public.control_room_execution_authority_rank_v1(text)
  from public, anon, authenticated, service_role;
revoke all on function public.control_room_resolve_project_graph_dispatch_v1(text,text)
  from public, anon, authenticated, service_role;
revoke all on function public.control_room_execute_builtin_capability_v1(text,uuid,jsonb)
  from public, anon, authenticated, service_role;
revoke all on function public.control_room_get_project_dispatch_runtime_v1(text)
  from public, anon, authenticated, service_role;
revoke all on function public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)
  from public, anon, authenticated, service_role;

grant execute on function public.control_room_execution_authority_rank_v1(text) to service_role;
grant execute on function public.control_room_resolve_project_graph_dispatch_v1(text,text) to service_role;
grant execute on function public.control_room_execute_builtin_capability_v1(text,uuid,jsonb) to service_role;
grant execute on function public.control_room_get_project_dispatch_runtime_v1(text) to service_role;
grant execute on function public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb) to service_role;

insert into public.control_room_execution_executors_v1(
  executor_key,
  executor_kind,
  status,
  description,
  max_authority_class,
  supported_execution_modes,
  metadata
)
values(
  'control_room.project_state.read.v1',
  'builtin',
  'active',
  'Reads the canonical Control Room Project State for the project that owns the graph run.',
  'read_only',
  array['server_executable','deterministic_code']::text[],
  jsonb_build_object(
    'milestone','PER-3',
    'side_effects','none',
    'cost','zero'
  )
)
on conflict (executor_key) do update
set
  executor_kind = excluded.executor_kind,
  status = excluded.status,
  description = excluded.description,
  max_authority_class = excluded.max_authority_class,
  supported_execution_modes = excluded.supported_execution_modes,
  metadata = excluded.metadata,
  updated_at = now();

insert into public.control_room_execution_capabilities_v1(
  capability_key,
  executor_key,
  status,
  description,
  max_authority_class,
  supported_execution_modes,
  supported_phases,
  input_contract,
  output_contract,
  metadata
)
values(
  'control_room.project_state.read',
  'control_room.project_state.read.v1',
  'active',
  'Reads canonical Control Room Project State through a bounded PER-3 dispatch route.',
  'read_only',
  array['server_executable','deterministic_code']::text[],
  array['execute']::text[],
  jsonb_build_object(
    'type','object',
    'additionalProperties',false
  ),
  jsonb_build_object(
    'type','object',
    'required',jsonb_build_array('project_key','project_state','observed_at')
  ),
  jsonb_build_object(
    'milestone','PER-3',
    'side_effects','none',
    'provider','control_room'
  )
)
on conflict (capability_key) do update
set
  executor_key = excluded.executor_key,
  status = excluded.status,
  description = excluded.description,
  max_authority_class = excluded.max_authority_class,
  supported_execution_modes = excluded.supported_execution_modes,
  supported_phases = excluded.supported_phases,
  input_contract = excluded.input_contract,
  output_contract = excluded.output_contract,
  metadata = excluded.metadata,
  updated_at = now();

insert into public.control_room_project_capability_bindings_v1(
  project_id,
  capability_key,
  status,
  max_authority_class,
  config
)
select
  p.id,
  'control_room.project_state.read',
  'active',
  'read_only',
  jsonb_build_object(
    'milestone','PER-3',
    'canary_allowed',true
  )
from public.control_room_projects p
where p.project_key = 'ai-company-os'
on conflict (project_id, capability_key) do update
set
  status = excluded.status,
  max_authority_class = excluded.max_authority_class,
  config = excluded.config,
  updated_at = now();

commit;
