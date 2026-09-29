begin;

-- Meterion Project Execution Runtime v1 — PER-1
-- Work Unit / Graph Run / Node / Edge contracts and persistence.
-- Project State remains canonical in control_room_project_state_versions/current views.
-- Run budgets/checkpoints remain canonical in control_room_run_envelopes.

create table if not exists public.control_room_project_work_units_v1 (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  work_unit_key text not null
    check (work_unit_key ~ '^[a-z0-9][a-z0-9._-]{1,199}$'),
  source_state_version integer not null check (source_state_version >= 0),
  objective text not null check (char_length(objective) between 1 and 5000),
  definition_of_done jsonb not null default '{}'::jsonb
    check (jsonb_typeof(definition_of_done) = 'object'),
  scope_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(scope_contract) = 'object'),
  preserve_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(preserve_contract) = 'object'),
  non_goals jsonb not null default '[]'::jsonb
    check (jsonb_typeof(non_goals) = 'array'),
  stop_gates jsonb not null default '[]'::jsonb
    check (jsonb_typeof(stop_gates) = 'array'),
  contract_hash text not null check (contract_hash ~ '^[0-9a-f]{32}$'),
  status text not null default 'planned'
    check (status in ('planned','active','waiting','completed','failed','cancelled')),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz null,
  unique (project_id, work_unit_key),
  unique (id, project_id)
);

create index if not exists control_room_project_work_units_v1_project_status_idx
  on public.control_room_project_work_units_v1(project_id, status, updated_at desc);

create table if not exists public.control_room_project_graph_runs_v1 (
  run_key text primary key references public.control_room_run_envelopes(run_key) on delete cascade,
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  work_unit_id uuid not null,
  graph_version integer not null default 1 check (graph_version between 1 and 1000000),
  compiler_version text not null default 'per1'
    check (char_length(compiler_version) between 1 and 100),
  contract_hash text not null check (contract_hash ~ '^[0-9a-f]{32}$'),
  status text not null default 'planned'
    check (status in ('planned','active','waiting','verifying','completed','failed','cancelled')),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  started_at timestamptz null,
  updated_at timestamptz not null default now(),
  completed_at timestamptz null,
  foreign key (work_unit_id, project_id)
    references public.control_room_project_work_units_v1(id, project_id)
    on delete cascade,
  unique (work_unit_id, graph_version)
);

create index if not exists control_room_project_graph_runs_v1_project_status_idx
  on public.control_room_project_graph_runs_v1(project_id, status, updated_at desc);

create table if not exists public.control_room_project_graph_nodes_v1 (
  id uuid primary key default gen_random_uuid(),
  graph_run_key text not null
    references public.control_room_project_graph_runs_v1(run_key) on delete cascade,
  node_key text not null
    check (node_key ~ '^[a-z0-9][a-z0-9._-]{1,199}$'),
  node_index integer not null check (node_index between 0 and 10000),
  node_type text not null
    check (node_type in ('worker','tool','code','verifier','router','join','human_gate')),
  action_kind text not null check (char_length(action_kind) between 1 and 200),
  purpose text not null check (char_length(purpose) between 1 and 5000),
  execution_mode text not null
    check (execution_mode in ('server_executable','chatgpt_session','human_gate','deterministic_code')),
  required_capability text null
    check (required_capability is null or required_capability ~ '^[a-z0-9][a-z0-9._-]{1,199}$'),
  input_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(input_contract) = 'object'),
  output_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(output_contract) = 'object'),
  verification_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(verification_contract) = 'object'),
  failure_policy text not null default 'stop'
    check (failure_policy in ('retry','fallback','skip','repair','escalate','stop')),
  max_attempts smallint not null default 1 check (max_attempts between 1 and 10),
  timeout_seconds integer not null default 300 check (timeout_seconds between 1 and 86400),
  idempotency_key text not null check (char_length(idempotency_key) between 1 and 500),
  authority_class text not null default 'read_only'
    check (authority_class in ('read_only','prepare','bounded_write','external_write','owner_gate')),
  status text not null default 'pending'
    check (status in (
      'pending','ready','running','waiting_dependency','waiting_session','waiting_owner',
      'verifying','completed','failed','skipped','cancelled'
    )),
  attempt_count integer not null default 0 check (attempt_count between 0 and 10),
  result jsonb null check (result is null or jsonb_typeof(result) = 'object'),
  evidence jsonb not null default '{}'::jsonb
    check (jsonb_typeof(evidence) = 'object'),
  started_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (graph_run_key, node_key),
  unique (graph_run_key, node_index),
  unique (graph_run_key, idempotency_key),
  unique (graph_run_key, id)
);

create index if not exists control_room_project_graph_nodes_v1_status_idx
  on public.control_room_project_graph_nodes_v1(graph_run_key, status, node_index);

create table if not exists public.control_room_project_graph_edges_v1 (
  id uuid primary key default gen_random_uuid(),
  graph_run_key text not null
    references public.control_room_project_graph_runs_v1(run_key) on delete cascade,
  from_node_id uuid not null,
  to_node_id uuid not null,
  edge_kind text not null
    check (edge_kind in ('data','control','authority','success','failure','verification')),
  required_status text not null default 'completed'
    check (required_status in ('completed','failed','terminal')),
  data_contract jsonb not null default '{}'::jsonb
    check (jsonb_typeof(data_contract) = 'object'),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  foreign key (graph_run_key, from_node_id)
    references public.control_room_project_graph_nodes_v1(graph_run_key, id)
    on delete cascade,
  foreign key (graph_run_key, to_node_id)
    references public.control_room_project_graph_nodes_v1(graph_run_key, id)
    on delete cascade,
  check (from_node_id <> to_node_id),
  unique (graph_run_key, from_node_id, to_node_id, edge_kind, required_status)
);

create index if not exists control_room_project_graph_edges_v1_to_idx
  on public.control_room_project_graph_edges_v1(graph_run_key, to_node_id);

create index if not exists control_room_project_graph_edges_v1_from_idx
  on public.control_room_project_graph_edges_v1(graph_run_key, from_node_id);

alter table public.control_room_project_work_units_v1 enable row level security;
alter table public.control_room_project_graph_runs_v1 enable row level security;
alter table public.control_room_project_graph_nodes_v1 enable row level security;
alter table public.control_room_project_graph_edges_v1 enable row level security;

revoke all on public.control_room_project_work_units_v1 from public, anon, authenticated;
revoke all on public.control_room_project_graph_runs_v1 from public, anon, authenticated;
revoke all on public.control_room_project_graph_nodes_v1 from public, anon, authenticated;
revoke all on public.control_room_project_graph_edges_v1 from public, anon, authenticated;

grant select, insert, update on public.control_room_project_work_units_v1 to service_role;
grant select, insert, update on public.control_room_project_graph_runs_v1 to service_role;
grant select, insert, update on public.control_room_project_graph_nodes_v1 to service_role;
grant select, insert on public.control_room_project_graph_edges_v1 to service_role;

create or replace function public.control_room_validate_project_graph_v1(p_run_key text)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_node_count integer;
  v_edge_count integer;
  v_has_cycle boolean;
begin
  if not exists (
    select 1 from public.control_room_project_graph_runs_v1 where run_key = p_run_key
  ) then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
  end if;

  select count(*) into v_node_count
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key;

  if v_node_count = 0 then
    raise exception 'graph_requires_nodes' using errcode = 'P0001';
  end if;

  select count(*) into v_edge_count
  from public.control_room_project_graph_edges_v1
  where graph_run_key = p_run_key;

  with recursive reach(from_node_id, to_node_id) as (
    select e.from_node_id, e.to_node_id
    from public.control_room_project_graph_edges_v1 e
    where e.graph_run_key = p_run_key
    union
    select r.from_node_id, e.to_node_id
    from reach r
    join public.control_room_project_graph_edges_v1 e
      on e.graph_run_key = p_run_key
     and e.from_node_id = r.to_node_id
  )
  select exists(
    select 1 from reach where from_node_id = to_node_id
  ) into v_has_cycle;

  if v_has_cycle then
    raise exception 'graph_cycle_detected' using errcode = 'P0001';
  end if;

  return jsonb_build_object(
    'valid', true,
    'run_key', p_run_key,
    'node_count', v_node_count,
    'edge_count', v_edge_count,
    'has_cycle', false
  );
end;
$$;

create or replace function public.control_room_get_project_work_graph_v1(p_run_key text)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'work_unit', to_jsonb(w),
    'graph_run', to_jsonb(g),
    'run_envelope', to_jsonb(r),
    'nodes', coalesce((
      select jsonb_agg(to_jsonb(n) order by n.node_index, n.node_key)
      from public.control_room_project_graph_nodes_v1 n
      where n.graph_run_key = g.run_key
    ), '[]'::jsonb),
    'edges', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', e.id,
          'from_node_key', fn.node_key,
          'to_node_key', tn.node_key,
          'edge_kind', e.edge_kind,
          'required_status', e.required_status,
          'data_contract', e.data_contract,
          'metadata', e.metadata,
          'created_at', e.created_at
        )
        order by fn.node_index, tn.node_index, e.edge_kind
      )
      from public.control_room_project_graph_edges_v1 e
      join public.control_room_project_graph_nodes_v1 fn
        on fn.graph_run_key = e.graph_run_key and fn.id = e.from_node_id
      join public.control_room_project_graph_nodes_v1 tn
        on tn.graph_run_key = e.graph_run_key and tn.id = e.to_node_id
      where e.graph_run_key = g.run_key
    ), '[]'::jsonb)
  )
  from public.control_room_project_graph_runs_v1 g
  join public.control_room_project_work_units_v1 w on w.id = g.work_unit_id
  join public.control_room_run_envelopes r on r.run_key = g.run_key
  where g.run_key = p_run_key
$$;

create or replace function public.control_room_refresh_project_graph_v1(p_run_key text)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_action_space jsonb;
  v_resume_from text;
  v_status text;
  v_envelope_status text;
  v_total integer;
  v_success_terminal integer;
  v_cancelled integer;
  v_stop_failed integer;
  v_active integer;
  v_waiting_session integer;
  v_waiting_owner integer;
begin
  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key
  for update;

  if not found then
    raise exception 'graph_run_not_found' using errcode = 'P0001';
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
    updated_at = now()
  where n.graph_run_key = p_run_key
    and n.status in ('pending','waiting_dependency');

  select
    count(*),
    count(*) filter (where status in ('completed','skipped')),
    count(*) filter (where status = 'cancelled'),
    count(*) filter (where status = 'failed' and failure_policy = 'stop'),
    count(*) filter (where status in ('ready','running','verifying')),
    count(*) filter (where status = 'waiting_session'),
    count(*) filter (where status = 'waiting_owner')
  into
    v_total, v_success_terminal, v_cancelled, v_stop_failed, v_active,
    v_waiting_session, v_waiting_owner
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key;

  if v_total = 0 then
    raise exception 'graph_requires_nodes' using errcode = 'P0001';
  end if;

  if v_stop_failed > 0 then
    v_status := 'failed';
  elsif v_success_terminal = v_total then
    v_status := 'completed';
  elsif v_success_terminal + v_cancelled = v_total and v_cancelled > 0 then
    v_status := 'cancelled';
  elsif v_active > 0 then
    v_status := 'active';
  else
    v_status := 'waiting';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'node_key', node_key,
        'node_type', node_type,
        'execution_mode', execution_mode,
        'required_capability', required_capability,
        'authority_class', authority_class
      )
      order by node_index, node_key
    ),
    '[]'::jsonb
  )
  into v_action_space
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key
    and status = 'ready';

  select node_key into v_resume_from
  from public.control_room_project_graph_nodes_v1
  where graph_run_key = p_run_key and status = 'ready'
  order by node_index, node_key
  limit 1;

  if v_resume_from is null then
    select node_key into v_resume_from
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and status = 'failed'
      and attempt_count < max_attempts
      and failure_policy in ('retry','repair','fallback')
    order by node_index, node_key
    limit 1;
  end if;

  if v_resume_from is null then
    select node_key into v_resume_from
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and status in ('waiting_session','waiting_owner')
    order by
      case status when 'waiting_session' then 0 else 1 end,
      node_index,
      node_key
    limit 1;
  end if;

  update public.control_room_project_graph_runs_v1
  set
    status = v_status,
    started_at = coalesce(started_at, case when v_status <> 'planned' then now() else null end),
    completed_at = case when v_status in ('completed','failed','cancelled') then coalesce(completed_at, now()) else completed_at end,
    updated_at = now()
  where run_key = p_run_key;

  update public.control_room_project_work_units_v1
  set
    status = case v_status
      when 'active' then 'active'
      when 'waiting' then 'waiting'
      when 'verifying' then 'active'
      when 'completed' then 'completed'
      when 'failed' then 'failed'
      when 'cancelled' then 'cancelled'
      else status
    end,
    completed_at = case when v_status in ('completed','failed','cancelled') then coalesce(completed_at, now()) else completed_at end,
    updated_at = now()
  where id = v_graph.work_unit_id;

  v_envelope_status := case v_status
    when 'active' then 'active'
    when 'waiting' then 'paused'
    when 'verifying' then 'active'
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
    stop_reason = case
      when v_status = 'failed' then 'graph_failed'
      when v_status = 'cancelled' then 'graph_cancelled'
      when v_waiting_owner > 0 and v_action_space = '[]'::jsonb then 'waiting_owner'
      when v_waiting_session > 0 and v_action_space = '[]'::jsonb then 'waiting_session'
      else null
    end,
    updated_at = now()
  where run_key = p_run_key;

  return public.control_room_get_project_work_graph_v1(p_run_key);
end;
$$;

create or replace function public.control_room_create_project_work_graph_v1(
  p_project_key text,
  p_work_unit_key text,
  p_run_key text,
  p_source_state_version integer,
  p_work_unit jsonb,
  p_nodes jsonb,
  p_edges jsonb,
  p_run_limits jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_project_id uuid;
  v_current_version integer;
  v_work_unit_id uuid;
  v_existing_hash text;
  v_work_unit_hash text;
  v_graph_hash text;
  v_node jsonb;
  v_edge jsonb;
  v_node_key text;
  v_from_id uuid;
  v_to_id uuid;
  v_ordinal bigint;
  v_validation jsonb;
begin
  if p_project_key is null or p_project_key !~ '^[a-z0-9][a-z0-9-]*$' then
    raise exception 'invalid_project_key' using errcode = 'P0001';
  end if;
  if p_work_unit_key is null or p_work_unit_key !~ '^[a-z0-9][a-z0-9._-]{1,199}$' then
    raise exception 'invalid_work_unit_key' using errcode = 'P0001';
  end if;
  if p_run_key is null or btrim(p_run_key) = '' or char_length(p_run_key) > 200 then
    raise exception 'invalid_run_key' using errcode = 'P0001';
  end if;
  if p_source_state_version is null or p_source_state_version < 0 then
    raise exception 'invalid_source_state_version' using errcode = 'P0001';
  end if;
  if p_work_unit is null or jsonb_typeof(p_work_unit) <> 'object' then
    raise exception 'work_unit_object_required' using errcode = 'P0001';
  end if;
  if nullif(btrim(p_work_unit->>'objective'),'') is null then
    raise exception 'work_unit_objective_required' using errcode = 'P0001';
  end if;
  if p_nodes is null or jsonb_typeof(p_nodes) <> 'array' or jsonb_array_length(p_nodes) = 0 then
    raise exception 'nodes_array_required' using errcode = 'P0001';
  end if;
  if p_edges is null or jsonb_typeof(p_edges) <> 'array' then
    raise exception 'edges_array_required' using errcode = 'P0001';
  end if;
  if p_run_limits is null or jsonb_typeof(p_run_limits) <> 'object' then
    raise exception 'run_limits_object_required' using errcode = 'P0001';
  end if;

  select p.id, s.version
  into v_project_id, v_current_version
  from public.control_room_projects p
  join public.control_room_project_current_v2 s on s.project_id = p.id
  where p.project_key = p_project_key;

  if v_project_id is null then
    raise exception 'project_or_state_not_found:%', p_project_key using errcode = 'P0001';
  end if;

  if v_current_version <> p_source_state_version then
    raise exception 'project_state_version_conflict:expected=%,actual=%',
      p_source_state_version, v_current_version using errcode = 'P0001';
  end if;

  v_work_unit_hash := md5(p_source_state_version::text || '|' || p_work_unit::text);
  v_graph_hash := md5(v_work_unit_hash || '|' || p_nodes::text || '|' || p_edges::text);

  select contract_hash into v_existing_hash
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key;

  if found then
    if v_existing_hash <> v_graph_hash then
      raise exception 'graph_run_contract_conflict' using errcode = 'P0001';
    end if;
    return public.control_room_get_project_work_graph_v1(p_run_key)
      || jsonb_build_object('idempotent_replay', true);
  end if;

  insert into public.control_room_project_work_units_v1(
    project_id,
    work_unit_key,
    source_state_version,
    objective,
    definition_of_done,
    scope_contract,
    preserve_contract,
    non_goals,
    stop_gates,
    contract_hash,
    status,
    metadata
  )
  values(
    v_project_id,
    p_work_unit_key,
    p_source_state_version,
    p_work_unit->>'objective',
    coalesce(p_work_unit->'definition_of_done','{}'::jsonb),
    coalesce(p_work_unit->'scope_contract','{}'::jsonb),
    coalesce(p_work_unit->'preserve_contract','{}'::jsonb),
    coalesce(p_work_unit->'non_goals','[]'::jsonb),
    coalesce(p_work_unit->'stop_gates','[]'::jsonb),
    v_work_unit_hash,
    'planned',
    coalesce(p_work_unit->'metadata','{}'::jsonb)
  )
  on conflict (project_id, work_unit_key) do nothing
  returning id into v_work_unit_id;

  if v_work_unit_id is null then
    select id, contract_hash
    into v_work_unit_id, v_existing_hash
    from public.control_room_project_work_units_v1
    where project_id = v_project_id
      and work_unit_key = p_work_unit_key;

    if v_existing_hash <> v_work_unit_hash then
      raise exception 'work_unit_contract_conflict' using errcode = 'P0001';
    end if;
  end if;

  insert into public.control_room_run_envelopes(
    run_key,
    project_id,
    status,
    max_actions,
    max_jev_calls,
    max_retries,
    max_spend_microusd,
    last_verified_checkpoint,
    action_space,
    context_filter,
    candidate_ranking,
    resume_from
  )
  values(
    p_run_key,
    v_project_id,
    'active',
    nullif(p_run_limits->>'max_actions','')::integer,
    nullif(p_run_limits->>'max_jev_calls','')::integer,
    nullif(p_run_limits->>'max_retries','')::integer,
    nullif(p_run_limits->>'max_spend_microusd','')::bigint,
    jsonb_build_object(
      'work_unit_key', p_work_unit_key,
      'graph_run_key', p_run_key,
      'completed_nodes', '[]'::jsonb,
      'source_state_version', p_source_state_version
    ),
    '[]'::jsonb,
    coalesce(p_run_limits->'context_filter','{}'::jsonb),
    '{}'::jsonb,
    null
  );

  insert into public.control_room_project_graph_runs_v1(
    run_key,
    project_id,
    work_unit_id,
    graph_version,
    compiler_version,
    contract_hash,
    status,
    metadata
  )
  values(
    p_run_key,
    v_project_id,
    v_work_unit_id,
    coalesce(nullif(p_work_unit->>'graph_version','')::integer, 1),
    coalesce(nullif(p_work_unit->>'compiler_version',''), 'per1'),
    v_graph_hash,
    'planned',
    jsonb_build_object(
      'source_state_version', p_source_state_version,
      'project_key', p_project_key
    )
  );

  for v_node, v_ordinal in
    select value, ordinality
    from jsonb_array_elements(p_nodes) with ordinality
  loop
    v_node_key := v_node->>'node_key';

    if v_node_key is null or v_node_key !~ '^[a-z0-9][a-z0-9._-]{1,199}$' then
      raise exception 'invalid_node_key' using errcode = 'P0001';
    end if;

    insert into public.control_room_project_graph_nodes_v1(
      graph_run_key,
      node_key,
      node_index,
      node_type,
      action_kind,
      purpose,
      execution_mode,
      required_capability,
      input_contract,
      output_contract,
      verification_contract,
      failure_policy,
      max_attempts,
      timeout_seconds,
      idempotency_key,
      authority_class,
      status,
      evidence
    )
    values(
      p_run_key,
      v_node_key,
      coalesce(nullif(v_node->>'node_index','')::integer, (v_ordinal - 1)::integer),
      coalesce(nullif(v_node->>'node_type',''), 'worker'),
      coalesce(nullif(v_node->>'action_kind',''), coalesce(nullif(v_node->>'node_type',''), 'worker')),
      coalesce(nullif(v_node->>'purpose',''), v_node_key),
      coalesce(nullif(v_node->>'execution_mode',''), 'server_executable'),
      nullif(v_node->>'required_capability',''),
      coalesce(v_node->'input_contract','{}'::jsonb),
      coalesce(v_node->'output_contract','{}'::jsonb),
      coalesce(v_node->'verification_contract','{}'::jsonb),
      coalesce(nullif(v_node->>'failure_policy',''), 'stop'),
      coalesce(nullif(v_node->>'max_attempts','')::smallint, 1),
      coalesce(nullif(v_node->>'timeout_seconds','')::integer, 300),
      coalesce(nullif(v_node->>'idempotency_key',''), p_run_key || ':' || v_node_key),
      coalesce(nullif(v_node->>'authority_class',''), 'read_only'),
      'pending',
      coalesce(v_node->'evidence','{}'::jsonb)
    );
  end loop;

  for v_edge in
    select value from jsonb_array_elements(p_edges)
  loop
    select id into v_from_id
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and node_key = v_edge->>'from';

    select id into v_to_id
    from public.control_room_project_graph_nodes_v1
    where graph_run_key = p_run_key
      and node_key = v_edge->>'to';

    if v_from_id is null or v_to_id is null then
      raise exception 'edge_node_not_found' using errcode = 'P0001';
    end if;

    insert into public.control_room_project_graph_edges_v1(
      graph_run_key,
      from_node_id,
      to_node_id,
      edge_kind,
      required_status,
      data_contract,
      metadata
    )
    values(
      p_run_key,
      v_from_id,
      v_to_id,
      coalesce(nullif(v_edge->>'edge_kind',''), 'control'),
      coalesce(nullif(v_edge->>'required_status',''), 'completed'),
      coalesce(v_edge->'data_contract','{}'::jsonb),
      coalesce(v_edge->'metadata','{}'::jsonb)
    );
  end loop;

  v_validation := public.control_room_validate_project_graph_v1(p_run_key);

  update public.control_room_project_work_units_v1
  set status = 'active', updated_at = now()
  where id = v_work_unit_id;

  return public.control_room_refresh_project_graph_v1(p_run_key)
    || jsonb_build_object(
      'validation', v_validation,
      'idempotent_replay', false
    );
end;
$$;

create or replace function public.control_room_transition_project_graph_node_v1(
  p_run_key text,
  p_node_key text,
  p_expected_status text,
  p_new_status text,
  p_result jsonb default null,
  p_evidence jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_work_unit_key text;
  v_checkpoint jsonb;
begin
  if p_evidence is null or jsonb_typeof(p_evidence) <> 'object' then
    raise exception 'evidence_object_required' using errcode = 'P0001';
  end if;
  if p_result is not null and jsonb_typeof(p_result) <> 'object' then
    raise exception 'result_object_required' using errcode = 'P0001';
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
    (v_node.status = 'ready' and p_new_status in ('running','waiting_session','waiting_owner','skipped','cancelled'))
    or (v_node.status = 'waiting_session' and p_new_status in ('ready','cancelled'))
    or (v_node.status = 'waiting_owner' and p_new_status in ('ready','cancelled'))
    or (v_node.status = 'running' and p_new_status in ('verifying','completed','failed','waiting_session','waiting_owner'))
    or (v_node.status = 'verifying' and p_new_status in ('completed','failed'))
  ) then
    raise exception 'invalid_node_transition:%->%', v_node.status, p_new_status using errcode = 'P0001';
  end if;

  if p_new_status = 'running' and v_node.attempt_count >= v_node.max_attempts then
    raise exception 'node_attempt_budget_exhausted' using errcode = 'P0001';
  end if;

  update public.control_room_project_graph_nodes_v1
  set
    status = p_new_status,
    attempt_count = attempt_count + case when p_new_status = 'running' then 1 else 0 end,
    result = case when p_result is not null then p_result else result end,
    evidence = evidence || p_evidence,
    started_at = case when p_new_status = 'running' then coalesce(started_at, now()) else started_at end,
    completed_at = case when p_new_status in ('completed','failed','skipped','cancelled') then now() else completed_at end,
    updated_at = now()
  where id = v_node.id;

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
  end if;

  return public.control_room_refresh_project_graph_v1(p_run_key);
end;
$$;

create or replace function public.control_room_retry_project_graph_node_v1(
  p_run_key text,
  p_node_key text
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_graph public.control_room_project_graph_runs_v1%rowtype;
begin
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

  select * into v_graph
  from public.control_room_project_graph_runs_v1
  where run_key = p_run_key;

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
    evidence = evidence || jsonb_build_object(
      'retry_requested_at', now(),
      'previous_result', coalesce(result, '{}'::jsonb)
    ),
    result = null,
    completed_at = null,
    updated_at = now()
  where id = v_node.id;

  return public.control_room_refresh_project_graph_v1(p_run_key);
end;
$$;

revoke all on function public.control_room_validate_project_graph_v1(text)
  from public, anon, authenticated;
revoke all on function public.control_room_get_project_work_graph_v1(text)
  from public, anon, authenticated;
revoke all on function public.control_room_refresh_project_graph_v1(text)
  from public, anon, authenticated;
revoke all on function public.control_room_create_project_work_graph_v1(text,text,text,integer,jsonb,jsonb,jsonb,jsonb)
  from public, anon, authenticated;
revoke all on function public.control_room_transition_project_graph_node_v1(text,text,text,text,jsonb,jsonb)
  from public, anon, authenticated;
revoke all on function public.control_room_retry_project_graph_node_v1(text,text)
  from public, anon, authenticated;

grant execute on function public.control_room_validate_project_graph_v1(text) to service_role;
grant execute on function public.control_room_get_project_work_graph_v1(text) to service_role;
grant execute on function public.control_room_refresh_project_graph_v1(text) to service_role;
grant execute on function public.control_room_create_project_work_graph_v1(text,text,text,integer,jsonb,jsonb,jsonb,jsonb) to service_role;
grant execute on function public.control_room_transition_project_graph_node_v1(text,text,text,text,jsonb,jsonb) to service_role;
grant execute on function public.control_room_retry_project_graph_node_v1(text,text) to service_role;

commit;
