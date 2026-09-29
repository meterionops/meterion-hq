begin;

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

drop function if exists public.control_room_execute_builtin_capability_v1(text,uuid,jsonb);

revoke all on function public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)
  to service_role;

commit;
