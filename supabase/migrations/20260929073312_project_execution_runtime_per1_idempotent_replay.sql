-- PER-1 idempotent create replay remains valid after Project State advances.

CREATE OR REPLACE FUNCTION public.control_room_create_project_work_graph_v1(p_project_key text, p_work_unit_key text, p_run_key text, p_source_state_version integer, p_work_unit jsonb, p_nodes jsonb, p_edges jsonb, p_run_limits jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $$
declare
  v_project_id uuid;
  v_current_version integer;
  v_work_unit_id uuid;
  v_existing_hash text;
  v_existing_project_key text;
  v_existing_work_unit_key text;
  v_existing_source_state_version integer;
  v_existing_work_unit_hash text;
  v_existing_max_actions integer;
  v_existing_max_jev_calls integer;
  v_existing_max_retries integer;
  v_existing_max_spend_microusd bigint;
  v_existing_context_filter jsonb;
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

  v_work_unit_hash := md5(p_source_state_version::text || '|' || p_work_unit::text);
  v_graph_hash := md5(v_work_unit_hash || '|' || p_nodes::text || '|' || p_edges::text);

  select
    g.contract_hash,
    p.project_key,
    w.work_unit_key,
    w.source_state_version,
    w.contract_hash,
    r.max_actions,
    r.max_jev_calls,
    r.max_retries,
    r.max_spend_microusd,
    r.context_filter
  into
    v_existing_hash,
    v_existing_project_key,
    v_existing_work_unit_key,
    v_existing_source_state_version,
    v_existing_work_unit_hash,
    v_existing_max_actions,
    v_existing_max_jev_calls,
    v_existing_max_retries,
    v_existing_max_spend_microusd,
    v_existing_context_filter
  from public.control_room_project_graph_runs_v1 g
  join public.control_room_project_work_units_v1 w on w.id = g.work_unit_id
  join public.control_room_projects p on p.id = g.project_id
  join public.control_room_run_envelopes r on r.run_key = g.run_key
  where g.run_key = p_run_key;

  if found then
    if v_existing_hash <> v_graph_hash
       or v_existing_work_unit_hash <> v_work_unit_hash
       or v_existing_project_key <> p_project_key
       or v_existing_work_unit_key <> p_work_unit_key
       or v_existing_source_state_version <> p_source_state_version then
      raise exception 'graph_run_contract_conflict' using errcode = 'P0001';
    end if;

    if v_existing_max_actions is distinct from nullif(p_run_limits->>'max_actions','')::integer
       or v_existing_max_jev_calls is distinct from nullif(p_run_limits->>'max_jev_calls','')::integer
       or v_existing_max_retries is distinct from nullif(p_run_limits->>'max_retries','')::integer
       or v_existing_max_spend_microusd is distinct from nullif(p_run_limits->>'max_spend_microusd','')::bigint
       or v_existing_context_filter is distinct from coalesce(p_run_limits->'context_filter','{}'::jsonb) then
      raise exception 'graph_run_limits_conflict' using errcode = 'P0001';
    end if;

    return public.control_room_get_project_work_graph_v1(p_run_key)
      || jsonb_build_object('idempotent_replay', true);
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

revoke all on function public.control_room_create_project_work_graph_v1(text,text,text,integer,jsonb,jsonb,jsonb,jsonb) from public, anon, authenticated;
grant execute on function public.control_room_create_project_work_graph_v1(text,text,text,integer,jsonb,jsonb,jsonb,jsonb) to service_role;
