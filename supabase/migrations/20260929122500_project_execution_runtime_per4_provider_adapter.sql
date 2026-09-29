-- Meterion Project Execution Runtime v1 — PER-4 Provider Adapter Bridge
-- Extends the verified PER-3 governed dispatch boundary with one replaceable,
-- connector-managed, read-only provider adapter. PER-2 remains the canonical
-- lease/action/retry owner.

begin;

create table if not exists public.control_room_execution_provider_adapters_v1 (
  adapter_key text primary key
    check (adapter_key ~ '^[a-z0-9][a-z0-9._-]{1,199}$'),
  provider_key text not null
    check (provider_key ~ '^[a-z0-9][a-z0-9._-]{1,99}$'),
  invocation_mode text not null
    check (invocation_mode in ('chatgpt_connector')),
  credential_mode text not null
    check (credential_mode in ('connector_managed')),
  status text not null default 'active'
    check (status in ('active','disabled')),
  allowed_operations text[] not null
    check (cardinality(allowed_operations) > 0),
  description text not null
    check (char_length(description) between 1 and 5000),
  metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(metadata)='object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.control_room_execution_provider_adapters_v1 enable row level security;
revoke all on public.control_room_execution_provider_adapters_v1
  from public,anon,authenticated,service_role;
grant select on public.control_room_execution_provider_adapters_v1 to service_role;

alter table public.control_room_execution_executors_v1
  add column if not exists provider_adapter_key text null,
  add column if not exists provider_operation text null;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_execution_executors_v1'::regclass
      and conname='control_room_execution_executors_v1_executor_kind_check'
  ) then
    alter table public.control_room_execution_executors_v1
      drop constraint control_room_execution_executors_v1_executor_kind_check;
  end if;

  alter table public.control_room_execution_executors_v1
    add constraint control_room_execution_executors_v1_executor_kind_check
    check (executor_kind in ('builtin','provider_adapter'));

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_execution_executors_v1'::regclass
      and conname='control_room_execution_executors_v1_provider_adapter_key_fkey'
  ) then
    alter table public.control_room_execution_executors_v1
      add constraint control_room_execution_executors_v1_provider_adapter_key_fkey
      foreign key (provider_adapter_key)
      references public.control_room_execution_provider_adapters_v1(adapter_key)
      on update cascade on delete restrict;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_execution_executors_v1'::regclass
      and conname='control_room_execution_executors_v1_provider_binding_check'
  ) then
    alter table public.control_room_execution_executors_v1
      add constraint control_room_execution_executors_v1_provider_binding_check
      check (
        (executor_kind='builtin' and provider_adapter_key is null and provider_operation is null)
        or (
          executor_kind='provider_adapter'
          and provider_adapter_key is not null
          and provider_operation is not null
          and provider_operation ~ '^[a-z0-9][a-z0-9._-]{1,99}$'
        )
      );
  end if;
end
$$;

create index if not exists control_room_execution_executors_v1_provider_adapter_idx
  on public.control_room_execution_executors_v1(provider_adapter_key)
  where provider_adapter_key is not null;

alter table public.control_room_project_graph_dispatches_v1
  add column if not exists provider_adapter_key text null,
  add column if not exists provider_operation text null,
  add column if not exists provider_invocation_key text null,
  add column if not exists provider_claim_key text null,
  add column if not exists provider_claim_hash text null,
  add column if not exists provider_finish_key text null,
  add column if not exists provider_finish_hash text null,
  add column if not exists execution_token uuid null;

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_project_graph_dispatches_v1'::regclass
      and conname='control_room_project_graph_dispatches_v1_status_check'
  ) then
    alter table public.control_room_project_graph_dispatches_v1
      drop constraint control_room_project_graph_dispatches_v1_status_check;
  end if;

  alter table public.control_room_project_graph_dispatches_v1
    add constraint control_room_project_graph_dispatches_v1_status_check
    check (status in (
      'planned','awaiting_provider','executing','completed','failed','rejected','waiting'
    ));

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_project_graph_dispatches_v1'::regclass
      and conname='control_room_project_graph_dispatches_v1_provider_adapter_key_f'
  ) then
    alter table public.control_room_project_graph_dispatches_v1
      add constraint control_room_project_graph_dispatches_v1_provider_adapter_key_f
      foreign key (provider_adapter_key)
      references public.control_room_execution_provider_adapters_v1(adapter_key)
      on update cascade on delete restrict;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_project_graph_dispatches_v1'::regclass
      and conname='control_room_project_graph_dispatches_v1_provider_invocation_ke'
  ) then
    alter table public.control_room_project_graph_dispatches_v1
      add constraint control_room_project_graph_dispatches_v1_provider_invocation_ke
      check (
        provider_invocation_key is null
        or char_length(provider_invocation_key) between 1 and 240
      );
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_project_graph_dispatches_v1'::regclass
      and conname='control_room_project_graph_dispatches_v1_provider_claim_hash_ch'
  ) then
    alter table public.control_room_project_graph_dispatches_v1
      add constraint control_room_project_graph_dispatches_v1_provider_claim_hash_ch
      check (provider_claim_hash is null or provider_claim_hash ~ '^[0-9a-f]{32}$');
  end if;

  if not exists (
    select 1 from pg_constraint
    where conrelid='public.control_room_project_graph_dispatches_v1'::regclass
      and conname='control_room_project_graph_dispatches_v1_provider_finish_hash_c'
  ) then
    alter table public.control_room_project_graph_dispatches_v1
      add constraint control_room_project_graph_dispatches_v1_provider_finish_hash_c
      check (provider_finish_hash is null or provider_finish_hash ~ '^[0-9a-f]{32}$');
  end if;
end
$$;

create index if not exists control_room_project_graph_dispatches_v1_provider_adapter_idx
  on public.control_room_project_graph_dispatches_v1(provider_adapter_key,created_at desc)
  where provider_adapter_key is not null;

CREATE OR REPLACE FUNCTION public.control_room_provider_payload_has_secret_keys_v1(p_payload jsonb)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
  with recursive walk(key_name, value) as (
    select null::text, p_payload
    where p_payload is not null

    union all

    select child.key_name, child.value
    from walk w
    cross join lateral (
      select e.key as key_name, e.value
      from jsonb_each(w.value) e
      where jsonb_typeof(w.value)='object'

      union all

      select null::text as key_name, a.value
      from jsonb_array_elements(w.value) a
      where jsonb_typeof(w.value)='array'
    ) child
  )
  select exists (
    select 1
    from walk
    where key_name is not null
      and (
        lower(key_name) ~ '(^|_)(token|secret|password|authorization|api[_-]?key|apikey|private[_-]?key|cookie|bearer)($|_)'
        or lower(key_name) in ('credential','credentials')
      )
  )
$$;

CREATE OR REPLACE FUNCTION public.control_room_resolve_provider_adapter_v1(p_executor_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_executor public.control_room_execution_executors_v1%rowtype;
  v_adapter public.control_room_execution_provider_adapters_v1%rowtype;
begin
  select * into v_executor
  from public.control_room_execution_executors_v1
  where executor_key=p_executor_key;

  if not found then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','executor_not_registered',
      'executor_key',p_executor_key
    );
  end if;

  if v_executor.status <> 'active' then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','executor_disabled',
      'executor_key',p_executor_key
    );
  end if;

  if v_executor.executor_kind <> 'provider_adapter' then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','executor_not_provider_adapter',
      'executor_key',p_executor_key,
      'executor_kind',v_executor.executor_kind
    );
  end if;

  if v_executor.provider_adapter_key is null or v_executor.provider_operation is null then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','provider_adapter_binding_missing',
      'executor_key',p_executor_key
    );
  end if;

  select * into v_adapter
  from public.control_room_execution_provider_adapters_v1
  where adapter_key=v_executor.provider_adapter_key;

  if not found then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','provider_adapter_not_registered',
      'executor_key',p_executor_key,
      'provider_adapter_key',v_executor.provider_adapter_key
    );
  end if;

  if v_adapter.status <> 'active' then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','provider_adapter_disabled',
      'executor_key',p_executor_key,
      'provider_adapter_key',v_adapter.adapter_key
    );
  end if;

  if not (v_executor.provider_operation = any(v_adapter.allowed_operations)) then
    return jsonb_build_object(
      'adapter_status','rejected',
      'error_code','provider_operation_not_allowed',
      'executor_key',p_executor_key,
      'provider_adapter_key',v_adapter.adapter_key,
      'provider_operation',v_executor.provider_operation
    );
  end if;

  return jsonb_build_object(
    'adapter_status','ready',
    'error_code',null,
    'executor_key',v_executor.executor_key,
    'provider_adapter_key',v_adapter.adapter_key,
    'provider_key',v_adapter.provider_key,
    'invocation_mode',v_adapter.invocation_mode,
    'credential_mode',v_adapter.credential_mode,
    'provider_operation',v_executor.provider_operation
  );
end
$$;

CREATE OR REPLACE FUNCTION public.control_room_validate_provider_dispatch_input_v1(p_project_id uuid, p_capability_key text, p_input jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_binding public.control_room_project_capability_bindings_v1%rowtype;
  v_repo text;
  v_allowed boolean;
begin
  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    return jsonb_build_object(
      'input_status','rejected',
      'error_code','provider_input_object_required'
    );
  end if;

  if public.control_room_provider_payload_has_secret_keys_v1(p_input) then
    return jsonb_build_object(
      'input_status','rejected',
      'error_code','provider_payload_secret_key_rejected'
    );
  end if;

  select * into v_binding
  from public.control_room_project_capability_bindings_v1
  where project_id=p_project_id
    and capability_key=p_capability_key;

  if not found or v_binding.status <> 'active' then
    return jsonb_build_object(
      'input_status','rejected',
      'error_code','provider_capability_binding_not_active'
    );
  end if;

  if p_capability_key='github.repository.read' then
    if (p_input - 'repository_full_name') <> '{}'::jsonb then
      return jsonb_build_object(
        'input_status','rejected',
        'error_code','provider_input_extra_fields_rejected'
      );
    end if;

    v_repo := nullif(btrim(p_input->>'repository_full_name'),'');
    if v_repo is null
       or v_repo !~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' then
      return jsonb_build_object(
        'input_status','rejected',
        'error_code','github_repository_full_name_invalid'
      );
    end if;

    if jsonb_typeof(v_binding.config->'repository_allowlist') <> 'array' then
      return jsonb_build_object(
        'input_status','rejected',
        'error_code','github_repository_allowlist_missing'
      );
    end if;

    select exists (
      select 1
      from jsonb_array_elements_text(v_binding.config->'repository_allowlist') x(value)
      where x.value=v_repo
    ) into v_allowed;

    if not v_allowed then
      return jsonb_build_object(
        'input_status','rejected',
        'error_code','github_repository_not_allowed',
        'repository_full_name',v_repo
      );
    end if;

    return jsonb_build_object(
      'input_status','ready',
      'error_code',null,
      'normalized_input',jsonb_build_object(
        'repository_full_name',v_repo
      )
    );
  end if;

  return jsonb_build_object(
    'input_status','rejected',
    'error_code','provider_input_validator_missing',
    'capability_key',p_capability_key
  );
end
$$;

CREATE OR REPLACE FUNCTION public.control_room_assert_provider_finish_payload_v1(p_capability_key text, p_dispatch_input jsonb, p_result jsonb, p_provider_evidence jsonb, p_provider_adapter_key text, p_provider_operation text, p_provider_invocation_key text, p_success boolean)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_repo text;
  v_visibility text;
begin
  if p_result is null or jsonb_typeof(p_result)<>'object'
     or p_provider_evidence is null or jsonb_typeof(p_provider_evidence)<>'object' then
    raise exception 'provider_finish_payload_object_required' using errcode='P0001';
  end if;

  if public.control_room_provider_payload_has_secret_keys_v1(p_result)
     or public.control_room_provider_payload_has_secret_keys_v1(p_provider_evidence) then
    raise exception 'provider_result_secret_key_rejected' using errcode='P0001';
  end if;

  if p_capability_key='github.repository.read' then
    if (p_provider_evidence
          - 'provider'
          - 'adapter_key'
          - 'operation'
          - 'provider_invocation_key'
          - 'credential_mode'
          - 'source_ref'
          - 'returned_by') <> '{}'::jsonb then
      raise exception 'github_provider_evidence_extra_fields_rejected' using errcode='P0001';
    end if;

    if p_provider_evidence->>'provider'<>'github'
       or p_provider_evidence->>'adapter_key' is distinct from p_provider_adapter_key
       or p_provider_evidence->>'operation' is distinct from p_provider_operation
       or p_provider_evidence->>'provider_invocation_key' is distinct from p_provider_invocation_key
       or p_provider_evidence->>'credential_mode'<>'connector_managed'
       or p_provider_evidence->>'returned_by'<>'connected_github_provider'
       or nullif(btrim(p_provider_evidence->>'source_ref'),'') is null then
      raise exception 'github_provider_evidence_mismatch' using errcode='P0001';
    end if;

    v_repo := p_dispatch_input->>'repository_full_name';

    if p_result->>'repository_full_name' is distinct from v_repo then
      raise exception 'github_provider_result_repository_mismatch' using errcode='P0001';
    end if;

    if p_success then
      if (p_result
            - 'repository_full_name'
            - 'default_branch'
            - 'visibility'
            - 'archived'
            - 'disabled'
            - 'provider_observed_at') <> '{}'::jsonb then
        raise exception 'github_provider_result_extra_fields_rejected' using errcode='P0001';
      end if;

      if nullif(btrim(p_result->>'default_branch'),'') is null
         or char_length(p_result->>'default_branch')>255 then
        raise exception 'github_provider_result_default_branch_invalid' using errcode='P0001';
      end if;

      v_visibility := p_result->>'visibility';
      if v_visibility is not null
         and v_visibility not in ('public','private','internal') then
        raise exception 'github_provider_result_visibility_invalid' using errcode='P0001';
      end if;

      if p_result ? 'archived'
         and jsonb_typeof(p_result->'archived') not in ('boolean','null') then
        raise exception 'github_provider_result_archived_invalid' using errcode='P0001';
      end if;

      if p_result ? 'disabled'
         and jsonb_typeof(p_result->'disabled') not in ('boolean','null') then
        raise exception 'github_provider_result_disabled_invalid' using errcode='P0001';
      end if;

      if nullif(btrim(p_result->>'provider_observed_at'),'') is null then
        raise exception 'github_provider_result_observed_at_missing' using errcode='P0001';
      end if;
    else
      if (p_result - 'repository_full_name') <> '{}'::jsonb then
        raise exception 'github_provider_failure_result_extra_fields_rejected' using errcode='P0001';
      end if;
    end if;

    return;
  end if;

  raise exception 'provider_finish_validator_missing:%',p_capability_key
    using errcode='P0001';
end
$$;

CREATE OR REPLACE FUNCTION public.control_room_get_project_dispatch_runtime_v1(p_run_key text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $$
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
        ),
        'awaiting_provider_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.status = 'awaiting_provider'
        ),
        'executing_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.status = 'executing'
        ),
        'provider_adapter_dispatch_count',(
          select count(*)
          from public.control_room_project_graph_dispatches_v1 d
          where d.graph_run_key = p_run_key
            and d.provider_adapter_key is not null
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

CREATE OR REPLACE FUNCTION public.control_room_dispatch_project_graph_node_v1(p_run_key text, p_node_key text, p_dispatch_key text, p_input jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_graph public.control_room_project_graph_runs_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_existing public.control_room_project_graph_dispatches_v1%rowtype;
  v_route jsonb;
  v_adapter jsonb;
  v_input_check jsonb;
  v_request jsonb;
  v_request_hash text;
  v_dispatch_status text;
  v_claim jsonb;
  v_lease_token uuid;
  v_phase text;
  v_provider_invocation_key text;
  v_result jsonb;
  v_evidence jsonb;
  v_response jsonb;
  v_runtime jsonb;
  v_error_state text;
  v_error_message text;
  v_project_key text;
  v_project_state jsonb;
begin
  if p_dispatch_key is null
     or btrim(p_dispatch_key) = ''
     or char_length(p_dispatch_key) > 240 then
    raise exception 'invalid_dispatch_key' using errcode = 'P0001';
  end if;

  if p_input is null or jsonb_typeof(p_input) <> 'object' then
    raise exception 'input_object_required' using errcode = 'P0001';
  end if;

  if public.control_room_provider_payload_has_secret_keys_v1(p_input) then
    raise exception 'dispatch_payload_secret_key_rejected' using errcode = 'P0001';
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
      graph_run_key,node_id,project_id,dispatch_key,request_hash,
      requested_capability,resolved_capability,executor_key,phase,
      authority_class,execution_mode,status,input,evidence,response,
      error_code,completed_at
    )
    values(
      p_run_key,v_node.id,v_graph.project_id,p_dispatch_key,v_request_hash,
      v_node.required_capability,
      case
        when v_route ? 'required_capability'
          and v_route->>'required_capability' = v_node.required_capability
          and exists (
            select 1 from public.control_room_execution_capabilities_v1 c
            where c.capability_key = v_node.required_capability
          )
        then v_node.required_capability
        else null
      end,
      nullif(v_route->>'executor_key',''),
      nullif(v_route->>'phase',''),
      v_node.authority_class,v_node.execution_mode,v_dispatch_status,p_input,
      jsonb_build_object('preflight',v_route),
      v_response,nullif(v_route->>'error_code',''),clock_timestamp()
    );

    return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
      || jsonb_build_object(
        'dispatch',v_response,
        'idempotent_dispatch_replay',false
      );
  end if;

  v_phase := v_route->>'phase';

  if v_route->>'executor_kind'='provider_adapter' then
    v_adapter := public.control_room_resolve_provider_adapter_v1(
      v_route->>'executor_key'
    );

    if v_adapter->>'adapter_status' <> 'ready' then
      v_response := jsonb_build_object(
        'dispatch_key',p_dispatch_key,
        'status','rejected',
        'route',v_route,
        'provider_adapter',v_adapter
      );

      insert into public.control_room_project_graph_dispatches_v1(
        graph_run_key,node_id,project_id,dispatch_key,request_hash,
        requested_capability,resolved_capability,executor_key,phase,
        authority_class,execution_mode,status,input,evidence,response,
        error_code,completed_at
      )
      values(
        p_run_key,v_node.id,v_graph.project_id,p_dispatch_key,v_request_hash,
        v_node.required_capability,v_route->>'required_capability',
        v_route->>'executor_key',v_phase,v_node.authority_class,
        v_node.execution_mode,'rejected',p_input,
        jsonb_build_object('preflight',v_route,'provider_adapter',v_adapter),
        v_response,v_adapter->>'error_code',clock_timestamp()
      );

      return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
        || jsonb_build_object(
          'dispatch',v_response,
          'idempotent_dispatch_replay',false
        );
    end if;

    v_input_check := public.control_room_validate_provider_dispatch_input_v1(
      v_graph.project_id,
      v_route->>'required_capability',
      p_input
    );

    if v_input_check->>'input_status' <> 'ready' then
      v_response := jsonb_build_object(
        'dispatch_key',p_dispatch_key,
        'status','rejected',
        'route',v_route,
        'provider_adapter',v_adapter,
        'provider_input',v_input_check
      );

      insert into public.control_room_project_graph_dispatches_v1(
        graph_run_key,node_id,project_id,dispatch_key,request_hash,
        requested_capability,resolved_capability,executor_key,phase,
        authority_class,execution_mode,status,input,evidence,response,
        error_code,completed_at,provider_adapter_key,provider_operation
      )
      values(
        p_run_key,v_node.id,v_graph.project_id,p_dispatch_key,v_request_hash,
        v_node.required_capability,v_route->>'required_capability',
        v_route->>'executor_key',v_phase,v_node.authority_class,
        v_node.execution_mode,'rejected',p_input,
        jsonb_build_object(
          'preflight',v_route,
          'provider_adapter',v_adapter,
          'provider_input',v_input_check
        ),
        v_response,v_input_check->>'error_code',clock_timestamp(),
        v_adapter->>'provider_adapter_key',
        v_adapter->>'provider_operation'
      );

      return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
        || jsonb_build_object(
          'dispatch',v_response,
          'idempotent_dispatch_replay',false
        );
    end if;

    v_provider_invocation_key :=
      'per4:' || md5(
        p_run_key || ':' || p_dispatch_key || ':' ||
        coalesce(v_adapter->>'provider_adapter_key','') || ':' ||
        coalesce(v_adapter->>'provider_operation','') || ':' ||
        v_request_hash
      );

    v_response := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'status','awaiting_provider',
      'route',v_route,
      'provider_handoff',jsonb_build_object(
        'provider_invocation_key',v_provider_invocation_key,
        'provider_adapter_key',v_adapter->>'provider_adapter_key',
        'provider_key',v_adapter->>'provider_key',
        'invocation_mode',v_adapter->>'invocation_mode',
        'credential_mode',v_adapter->>'credential_mode',
        'provider_operation',v_adapter->>'provider_operation',
        'input',v_input_check->'normalized_input'
      )
    );

    insert into public.control_room_project_graph_dispatches_v1(
      graph_run_key,node_id,project_id,dispatch_key,request_hash,
      requested_capability,resolved_capability,executor_key,phase,
      authority_class,execution_mode,status,input,evidence,response,
      provider_adapter_key,provider_operation,provider_invocation_key
    )
    values(
      p_run_key,v_node.id,v_graph.project_id,p_dispatch_key,v_request_hash,
      v_node.required_capability,v_route->>'required_capability',
      v_route->>'executor_key',v_phase,v_node.authority_class,
      v_node.execution_mode,'awaiting_provider',v_input_check->'normalized_input',
      jsonb_build_object(
        'preflight',v_route,
        'provider_adapter',v_adapter,
        'provider_input',v_input_check
      ),
      v_response,
      v_adapter->>'provider_adapter_key',
      v_adapter->>'provider_operation',
      v_provider_invocation_key
    );

    return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
      || jsonb_build_object(
        'dispatch',v_response,
        'idempotent_dispatch_replay',false
      );
  end if;

  insert into public.control_room_project_graph_dispatches_v1(
    graph_run_key,node_id,project_id,dispatch_key,request_hash,
    requested_capability,resolved_capability,executor_key,phase,
    authority_class,execution_mode,status,input,evidence,response
  )
  values(
    p_run_key,v_node.id,v_graph.project_id,p_dispatch_key,v_request_hash,
    v_node.required_capability,v_route->>'required_capability',
    v_route->>'executor_key',v_phase,v_node.authority_class,
    v_node.execution_mode,'planned',p_input,
    jsonb_build_object('preflight',v_route),'{}'::jsonb
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
  set status='executing', started_at=clock_timestamp(), updated_at=now()
  where graph_run_key=p_run_key and dispatch_key=p_dispatch_key;

  begin
    if v_route->>'executor_kind' <> 'builtin' then
      raise exception 'executor_kind_not_supported:%', v_route->>'executor_kind'
        using errcode = 'P0001';
    end if;

    if v_route->>'executor_key' = 'control_room.project_state.read.v1' then
      select project_key into v_project_key
      from public.control_room_projects
      where id = v_graph.project_id;

      if not found then
        raise exception 'project_not_found' using errcode = 'P0001';
      end if;

      v_project_state := public.control_room_get_project_state_v3(v_project_key);

      v_result := jsonb_build_object(
        'project_key',v_project_key,
        'project_state',v_project_state,
        'observed_at',clock_timestamp()
      );
    else
      raise exception 'builtin_executor_not_supported:%', v_route->>'executor_key'
        using errcode = 'P0001';
    end if;

    v_evidence := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'capability_key',v_route->>'required_capability',
      'executor_key',v_route->>'executor_key',
      'phase',v_phase,
      'dispatched_at',clock_timestamp()
    );

    if v_phase='execute' then
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':complete',
        'running','completed',v_lease_token,v_result,
        jsonb_build_object('dispatch',v_evidence),'{}'::jsonb
      );
    else
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':complete',
        'verifying','completed',v_lease_token,v_result,
        jsonb_build_object('dispatch',v_evidence),'{}'::jsonb
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
    set status='completed',result=v_result,
        evidence=evidence || jsonb_build_object('execution',v_evidence),
        response=v_response,completed_at=clock_timestamp(),updated_at=now()
    where graph_run_key=p_run_key and dispatch_key=p_dispatch_key;

  exception when others then
    get stacked diagnostics
      v_error_state=returned_sqlstate,
      v_error_message=message_text;

    v_evidence := jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'capability_key',v_route->>'required_capability',
      'executor_key',v_route->>'executor_key',
      'phase',v_phase,
      'error_sqlstate',v_error_state,
      'error_message',v_error_message
    );

    if v_phase='execute' then
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':failed',
        'running','failed',v_lease_token,
        jsonb_build_object(
          'error_code','executor_failed',
          'sqlstate',v_error_state,
          'message',v_error_message
        ),
        jsonb_build_object('dispatch',v_evidence),'{}'::jsonb
      );
    else
      perform public.control_room_transition_project_graph_node_v2(
        p_run_key,p_node_key,
        'per3-dispatch:' || p_dispatch_key || ':failed',
        'verifying','failed',v_lease_token,
        jsonb_build_object(
          'error_code','executor_failed',
          'sqlstate',v_error_state,
          'message',v_error_message
        ),
        jsonb_build_object('dispatch',v_evidence),'{}'::jsonb
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
    set status='failed',
        result=jsonb_build_object(
          'error_code','executor_failed',
          'sqlstate',v_error_state,
          'message',v_error_message
        ),
        evidence=evidence || jsonb_build_object('execution',v_evidence),
        response=v_response,error_code='executor_failed',
        completed_at=clock_timestamp(),updated_at=now()
    where graph_run_key=p_run_key and dispatch_key=p_dispatch_key;
  end;

  v_runtime := public.control_room_get_project_dispatch_runtime_v1(p_run_key);

  return v_runtime || jsonb_build_object(
    'dispatch',v_response,
    'idempotent_dispatch_replay',false
  );
end
$$;

CREATE OR REPLACE FUNCTION public.control_room_claim_project_graph_provider_dispatch_v1(p_run_key text, p_dispatch_key text, p_claim_key text, p_lease_seconds integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_dispatch public.control_room_project_graph_dispatches_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_route jsonb;
  v_adapter jsonb;
  v_input_check jsonb;
  v_claim jsonb;
  v_claim_request jsonb;
  v_claim_hash text;
  v_lease_token uuid;
  v_provider_claim jsonb;
begin
  if p_claim_key is null or btrim(p_claim_key)='' or char_length(p_claim_key)>200 then
    raise exception 'invalid_provider_claim_key' using errcode='P0001';
  end if;

  if p_lease_seconds is not null and (p_lease_seconds<1 or p_lease_seconds>86400) then
    raise exception 'invalid_lease_seconds' using errcode='P0001';
  end if;

  v_claim_request := jsonb_build_object(
    'run_key',p_run_key,
    'dispatch_key',p_dispatch_key,
    'claim_key',p_claim_key,
    'lease_seconds',p_lease_seconds
  );
  v_claim_hash := md5(v_claim_request::text);

  perform pg_advisory_xact_lock(
    hashtextextended(p_run_key || ':' || p_dispatch_key || ':provider-claim',0)
  );

  select * into v_dispatch
  from public.control_room_project_graph_dispatches_v1
  where graph_run_key=p_run_key and dispatch_key=p_dispatch_key
  for update;

  if not found then
    raise exception 'provider_dispatch_not_found' using errcode='P0001';
  end if;

  if v_dispatch.provider_claim_key is not null then
    if v_dispatch.provider_claim_key<>p_claim_key
       or v_dispatch.provider_claim_hash<>v_claim_hash then
      raise exception 'provider_claim_key_conflict' using errcode='P0001';
    end if;

    v_provider_claim := coalesce(
      v_dispatch.response->'provider_claim',
      jsonb_build_object(
        'dispatch_key',p_dispatch_key,
        'status',v_dispatch.status,
        'provider_invocation_key',v_dispatch.provider_invocation_key,
        'provider_adapter_key',v_dispatch.provider_adapter_key,
        'provider_operation',v_dispatch.provider_operation,
        'lease_token',v_dispatch.execution_token,
        'input',v_dispatch.input
      )
    );

    return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
      || jsonb_build_object(
        'provider_claim',v_provider_claim,
        'idempotent_provider_claim_replay',true
      );
  end if;

  if v_dispatch.status<>'awaiting_provider' then
    raise exception 'provider_dispatch_not_claimable:%',v_dispatch.status
      using errcode='P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key=p_run_key and id=v_dispatch.node_id
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode='P0001';
  end if;

  v_route := public.control_room_resolve_project_graph_dispatch_v1(
    p_run_key,v_node.node_key
  );

  if v_route->>'route_status'<>'dispatchable'
     or v_route->>'executor_key' is distinct from v_dispatch.executor_key
     or v_route->>'required_capability' is distinct from v_dispatch.resolved_capability then
    raise exception 'provider_dispatch_route_changed:%',v_route using errcode='P0001';
  end if;

  v_adapter := public.control_room_resolve_provider_adapter_v1(
    v_dispatch.executor_key
  );

  if v_adapter->>'adapter_status'<>'ready'
     or v_adapter->>'provider_adapter_key' is distinct from v_dispatch.provider_adapter_key
     or v_adapter->>'provider_operation' is distinct from v_dispatch.provider_operation then
    raise exception 'provider_adapter_not_ready:%',v_adapter using errcode='P0001';
  end if;

  v_input_check := public.control_room_validate_provider_dispatch_input_v1(
    v_dispatch.project_id,
    v_dispatch.resolved_capability,
    v_dispatch.input
  );

  if v_input_check->>'input_status'<>'ready' then
    raise exception 'provider_dispatch_input_no_longer_valid:%',v_input_check
      using errcode='P0001';
  end if;

  v_claim := public.control_room_claim_project_graph_node_v2(
    p_run_key,
    v_node.node_key,
    'per4-provider-claim:' || md5(p_run_key || ':' || p_dispatch_key || ':' || p_claim_key),
    p_lease_seconds
  );

  if v_claim->'claim'->>'phase' <> 'execute' then
    raise exception 'provider_dispatch_phase_changed:%',
      v_claim->'claim'->>'phase' using errcode='P0001';
  end if;

  v_lease_token := (v_claim->'claim'->>'lease_token')::uuid;

  v_provider_claim := jsonb_build_object(
    'dispatch_key',p_dispatch_key,
    'status','executing',
    'provider_invocation_key',v_dispatch.provider_invocation_key,
    'provider_adapter_key',v_dispatch.provider_adapter_key,
    'provider_key',v_adapter->>'provider_key',
    'invocation_mode',v_adapter->>'invocation_mode',
    'credential_mode',v_adapter->>'credential_mode',
    'provider_operation',v_dispatch.provider_operation,
    'lease_token',v_lease_token,
    'lease_expires_at',v_claim->'claim'->>'lease_expires_at',
    'input',v_input_check->'normalized_input'
  );

  update public.control_room_project_graph_dispatches_v1
  set
    status='executing',
    provider_claim_key=p_claim_key,
    provider_claim_hash=v_claim_hash,
    execution_token=v_lease_token,
    started_at=coalesce(started_at,clock_timestamp()),
    response=response || jsonb_build_object(
      'status','executing',
      'provider_claim',v_provider_claim
    ),
    evidence=evidence || jsonb_build_object(
      'provider_claim',jsonb_build_object(
        'provider_invocation_key',provider_invocation_key,
        'provider_adapter_key',provider_adapter_key,
        'provider_operation',provider_operation,
        'claimed_at',clock_timestamp()
      )
    ),
    updated_at=now()
  where id=v_dispatch.id;

  return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
    || jsonb_build_object(
      'provider_claim',v_provider_claim,
      'idempotent_provider_claim_replay',false
    );
end
$$;

CREATE OR REPLACE FUNCTION public.control_room_finish_project_graph_provider_dispatch_v1(p_run_key text, p_dispatch_key text, p_finish_key text, p_lease_token uuid, p_success boolean, p_result jsonb DEFAULT '{}'::jsonb, p_provider_evidence jsonb DEFAULT '{}'::jsonb, p_error_code text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_dispatch public.control_room_project_graph_dispatches_v1%rowtype;
  v_node public.control_room_project_graph_nodes_v1%rowtype;
  v_finish_request jsonb;
  v_finish_hash text;
  v_transition_key text;
  v_result jsonb;
  v_evidence jsonb;
  v_response jsonb;
begin
  if p_finish_key is null or btrim(p_finish_key)='' or char_length(p_finish_key)>200 then
    raise exception 'invalid_provider_finish_key' using errcode='P0001';
  end if;

  if p_lease_token is null then
    raise exception 'provider_finish_lease_token_required' using errcode='P0001';
  end if;

  if p_result is null or jsonb_typeof(p_result)<>'object' then
    raise exception 'provider_result_object_required' using errcode='P0001';
  end if;

  if p_provider_evidence is null or jsonb_typeof(p_provider_evidence)<>'object' then
    raise exception 'provider_evidence_object_required' using errcode='P0001';
  end if;

  if public.control_room_provider_payload_has_secret_keys_v1(p_result)
     or public.control_room_provider_payload_has_secret_keys_v1(p_provider_evidence) then
    raise exception 'provider_result_secret_key_rejected' using errcode='P0001';
  end if;

  if not p_success and (p_error_code is null or btrim(p_error_code)='') then
    raise exception 'provider_error_code_required' using errcode='P0001';
  end if;

  v_finish_request := jsonb_build_object(
    'run_key',p_run_key,
    'dispatch_key',p_dispatch_key,
    'finish_key',p_finish_key,
    'success',p_success,
    'result',p_result,
    'provider_evidence',p_provider_evidence,
    'error_code',p_error_code
  );
  v_finish_hash := md5(v_finish_request::text);

  perform pg_advisory_xact_lock(
    hashtextextended(p_run_key || ':' || p_dispatch_key || ':provider-finish',0)
  );

  select * into v_dispatch
  from public.control_room_project_graph_dispatches_v1
  where graph_run_key=p_run_key and dispatch_key=p_dispatch_key
  for update;

  if not found then
    raise exception 'provider_dispatch_not_found' using errcode='P0001';
  end if;

  perform public.control_room_assert_provider_finish_payload_v1(
    v_dispatch.resolved_capability,
    v_dispatch.input,
    p_result,
    p_provider_evidence,
    v_dispatch.provider_adapter_key,
    v_dispatch.provider_operation,
    v_dispatch.provider_invocation_key,
    p_success
  );

  if v_dispatch.provider_finish_key is not null then
    if v_dispatch.provider_finish_key<>p_finish_key
       or v_dispatch.provider_finish_hash<>v_finish_hash then
      raise exception 'provider_finish_key_conflict' using errcode='P0001';
    end if;

    return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
      || jsonb_build_object(
        'provider_finish',v_dispatch.response->'provider_finish',
        'idempotent_provider_finish_replay',true
      );
  end if;

  if v_dispatch.status<>'executing' then
    raise exception 'provider_dispatch_not_finishing:%',v_dispatch.status
      using errcode='P0001';
  end if;

  if v_dispatch.execution_token is null
     or v_dispatch.execution_token is distinct from p_lease_token then
    raise exception 'provider_finish_invalid_lease_token' using errcode='P0001';
  end if;

  select * into v_node
  from public.control_room_project_graph_nodes_v1
  where graph_run_key=p_run_key and id=v_dispatch.node_id
  for update;

  if not found then
    raise exception 'graph_node_not_found' using errcode='P0001';
  end if;

  v_result := case
    when p_success then p_result
    else p_result || jsonb_build_object('error_code',p_error_code)
  end;

  v_evidence := jsonb_build_object(
    'provider_dispatch',jsonb_build_object(
      'dispatch_key',p_dispatch_key,
      'provider_invocation_key',v_dispatch.provider_invocation_key,
      'provider_adapter_key',v_dispatch.provider_adapter_key,
      'provider_operation',v_dispatch.provider_operation,
      'provider_evidence',p_provider_evidence,
      'finished_at',clock_timestamp()
    )
  );

  v_transition_key :=
    'per4-provider-finish:' ||
    md5(p_run_key || ':' || p_dispatch_key || ':' || p_finish_key);

  perform public.control_room_transition_project_graph_node_v2(
    p_run_key,
    v_node.node_key,
    v_transition_key,
    'running',
    case when p_success then 'completed' else 'failed' end,
    p_lease_token,
    v_result,
    v_evidence,
    '{}'::jsonb
  );

  v_response := jsonb_build_object(
    'dispatch_key',p_dispatch_key,
    'status',case when p_success then 'completed' else 'failed' end,
    'provider_finish',jsonb_build_object(
      'success',p_success,
      'provider_invocation_key',v_dispatch.provider_invocation_key,
      'provider_adapter_key',v_dispatch.provider_adapter_key,
      'provider_operation',v_dispatch.provider_operation,
      'result',v_result,
      'evidence',p_provider_evidence,
      'error_code',case when p_success then null else p_error_code end
    )
  );

  update public.control_room_project_graph_dispatches_v1
  set
    status=case when p_success then 'completed' else 'failed' end,
    result=v_result,
    evidence=evidence || v_evidence,
    response=response || v_response,
    error_code=case when p_success then null else p_error_code end,
    provider_finish_key=p_finish_key,
    provider_finish_hash=v_finish_hash,
    execution_token=null,
    completed_at=clock_timestamp(),
    updated_at=now()
  where id=v_dispatch.id;

  return public.control_room_get_project_dispatch_runtime_v1(p_run_key)
    || jsonb_build_object(
      'provider_finish',v_response->'provider_finish',
      'idempotent_provider_finish_replay',false
    );
end
$$;

CREATE OR REPLACE FUNCTION public.control_room_sync_provider_dispatch_on_node_recovery_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
begin
  if old.execution_token is not null
     and new.execution_token is null
     and old.status in ('running','verifying')
     and new.status in ('ready','failed')
     and new.last_recovered_at is not null
     and new.last_recovered_at is distinct from old.last_recovered_at
     and new.evidence ? 'last_recovery' then

    update public.control_room_project_graph_dispatches_v1
    set
      status='failed',
      error_code=case
        when new.status='ready' then 'provider_execution_interrupted_requeued'
        else 'provider_execution_interrupted_failed'
      end,
      evidence=evidence || jsonb_build_object(
        'provider_recovery',jsonb_build_object(
          'from_node_status',old.status,
          'to_node_status',new.status,
          'execution_epoch',old.execution_epoch,
          'interruption_count',new.interruption_count,
          'recovered_at',clock_timestamp()
        )
      ),
      response=response || jsonb_build_object(
        'status','failed',
        'provider_recovery',jsonb_build_object(
          'node_status',new.status,
          'execution_epoch',old.execution_epoch
        )
      ),
      execution_token=null,
      completed_at=coalesce(completed_at,clock_timestamp()),
      updated_at=now()
    where graph_run_key=new.graph_run_key
      and node_id=new.id
      and provider_adapter_key is not null
      and status='executing'
      and execution_token=old.execution_token;
  end if;

  return new;
end
$$;

drop trigger if exists control_room_sync_provider_dispatch_on_node_recovery_v1
  on public.control_room_project_graph_nodes_v1;

create trigger control_room_sync_provider_dispatch_on_node_recovery_v1
after update of status,execution_token on public.control_room_project_graph_nodes_v1
for each row
execute function public.control_room_sync_provider_dispatch_on_node_recovery_v1();

revoke all on function public.control_room_provider_payload_has_secret_keys_v1(jsonb)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_resolve_provider_adapter_v1(text)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_validate_provider_dispatch_input_v1(uuid,text,jsonb)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_assert_provider_finish_payload_v1(text,jsonb,jsonb,jsonb,text,text,text,boolean)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_get_project_dispatch_runtime_v1(text)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_claim_project_graph_provider_dispatch_v1(text,text,text,integer)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_finish_project_graph_provider_dispatch_v1(text,text,text,uuid,boolean,jsonb,jsonb,text)
  from public,anon,authenticated,service_role;
revoke all on function public.control_room_sync_provider_dispatch_on_node_recovery_v1()
  from public,anon,authenticated,service_role;

grant execute on function public.control_room_provider_payload_has_secret_keys_v1(jsonb) to service_role;
grant execute on function public.control_room_resolve_provider_adapter_v1(text) to service_role;
grant execute on function public.control_room_validate_provider_dispatch_input_v1(uuid,text,jsonb) to service_role;
grant execute on function public.control_room_assert_provider_finish_payload_v1(text,jsonb,jsonb,jsonb,text,text,text,boolean) to service_role;
grant execute on function public.control_room_get_project_dispatch_runtime_v1(text) to service_role;
grant execute on function public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb) to service_role;
grant execute on function public.control_room_claim_project_graph_provider_dispatch_v1(text,text,text,integer) to service_role;
grant execute on function public.control_room_finish_project_graph_provider_dispatch_v1(text,text,text,uuid,boolean,jsonb,jsonb,text) to service_role;

insert into public.control_room_execution_provider_adapters_v1(
  adapter_key,provider_key,invocation_mode,credential_mode,status,
  allowed_operations,description,metadata
) values (
  'github.connector.read.v1','github','chatgpt_connector','connector_managed','active',
  array['get_repo']::text[],
  'Read-only GitHub connector adapter. Credentials remain managed by the connected GitHub provider and are never stored in Project Runtime payloads.',
  jsonb_build_object(
    'milestone','PER-4',
    'authority','read_only',
    'credentials','connector_managed',
    'worker_model','session_handoff_until_per5'
  )
)
on conflict (adapter_key) do update set
  provider_key=excluded.provider_key,
  invocation_mode=excluded.invocation_mode,
  credential_mode=excluded.credential_mode,
  status=excluded.status,
  allowed_operations=excluded.allowed_operations,
  description=excluded.description,
  metadata=excluded.metadata,
  updated_at=now();

insert into public.control_room_execution_executors_v1(
  executor_key,executor_kind,status,description,max_authority_class,
  supported_execution_modes,metadata,provider_adapter_key,provider_operation
) values (
  'github.repository.read.v1','provider_adapter','active',
  'Read GitHub repository metadata through the connector-managed GitHub provider adapter.',
  'read_only',array['server_executable']::text[],
  jsonb_build_object('milestone','PER-4','side_effects','none','provider','github'),
  'github.connector.read.v1','get_repo'
)
on conflict (executor_key) do update set
  executor_kind=excluded.executor_kind,
  status=excluded.status,
  description=excluded.description,
  max_authority_class=excluded.max_authority_class,
  supported_execution_modes=excluded.supported_execution_modes,
  metadata=excluded.metadata,
  provider_adapter_key=excluded.provider_adapter_key,
  provider_operation=excluded.provider_operation,
  updated_at=now();

insert into public.control_room_execution_capabilities_v1(
  capability_key,executor_key,status,description,max_authority_class,
  supported_execution_modes,supported_phases,input_contract,output_contract,metadata
) values (
  'github.repository.read','github.repository.read.v1','active',
  'Read bounded repository metadata through the governed GitHub provider adapter.',
  'read_only',array['server_executable']::text[],array['execute']::text[],
  jsonb_build_object(
    'type','object',
    'required',jsonb_build_array('repository_full_name'),
    'additionalProperties',false
  ),
  jsonb_build_object(
    'type','object',
    'required',jsonb_build_array('repository_full_name','default_branch')
  ),
  jsonb_build_object('milestone','PER-4','provider','github','side_effects','none')
)
on conflict (capability_key) do update set
  executor_key=excluded.executor_key,
  status=excluded.status,
  description=excluded.description,
  max_authority_class=excluded.max_authority_class,
  supported_execution_modes=excluded.supported_execution_modes,
  supported_phases=excluded.supported_phases,
  input_contract=excluded.input_contract,
  output_contract=excluded.output_contract,
  metadata=excluded.metadata,
  updated_at=now();

insert into public.control_room_project_capability_bindings_v1(
  project_id,capability_key,status,max_authority_class,config
)
select
  p.id,'github.repository.read','active','read_only',
  jsonb_build_object(
    'milestone','PER-4',
    'canary_allowed',true,
    'repository_allowlist',jsonb_build_array('meterionops/meterion-hq')
  )
from public.control_room_projects p
where p.project_key='ai-company-os'
on conflict (project_id,capability_key) do update set
  status=excluded.status,
  max_authority_class=excluded.max_authority_class,
  config=excluded.config,
  updated_at=now();

commit;
