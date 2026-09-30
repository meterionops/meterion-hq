CREATE OR REPLACE FUNCTION public.control_room_project_parallel_limit_v1(p_run_key text)
RETURNS integer LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $$
declare v_cfg jsonb; v_limit text;
begin
 select w.scope_contract->'per6' into v_cfg
 from public.control_room_project_graph_runs_v1 g
 join public.control_room_project_work_units_v1 w on w.id=g.work_unit_id
 where g.run_key=p_run_key;
 if not found then raise exception 'graph_run_not_found'; end if;
 if v_cfg is null then return null; end if;
 v_limit:=v_cfg->>'max_parallel_nodes';
 if jsonb_typeof(v_cfg)<>'object' or v_limit is null or v_limit !~ '^[1-4]$'
    or jsonb_typeof(v_cfg->'max_parallel_nodes')<>'number' then
   raise exception 'invalid_per6_parallel_contract';
 end if;
 return v_limit::integer;
end $$;
REVOKE ALL ON FUNCTION public.control_room_project_parallel_limit_v1(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.control_room_project_parallel_limit_v1(text) TO service_role;

CREATE OR REPLACE FUNCTION public.control_room_claim_project_graph_node_v2(p_run_key text, p_node_key text, p_claim_key text, p_lease_seconds integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_parallel_limit integer;
  v_active integer;
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

  -- PER-6 opt-in guard: graph FOR UPDATE above serializes all claims.
  v_parallel_limit := public.control_room_project_parallel_limit_v1(p_run_key);
  if v_parallel_limit is not null then
    if v_graph.status <> 'active' then raise exception 'per6_graph_not_active'; end if;
    if v_node.authority_class <> 'read_only'
       or v_node.execution_mode not in ('server_executable','deterministic_code') then
      raise exception 'per6_node_not_read_only_executable';
    end if;
    if exists (
      select 1 from public.control_room_project_graph_edges_v1 e
      join public.control_room_project_graph_nodes_v1 s
        on s.graph_run_key=e.graph_run_key and s.id=e.from_node_id
      where e.graph_run_key=p_run_key and e.to_node_id=v_node.id
        and not ((e.required_status='completed' and s.status='completed')
          or (e.required_status='failed' and s.status='failed')
          or (e.required_status='terminal' and s.status in ('completed','failed','skipped','cancelled')))
    ) then raise exception 'per6_dependencies_not_ready'; end if;
    select count(*) into v_active
    from public.control_room_project_graph_nodes_v1
    where graph_run_key=p_run_key and id<>v_node.id and status in ('running','verifying');
    if v_active >= v_parallel_limit then raise exception 'per6_parallel_limit_reached'; end if;
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
$function$;

CREATE OR REPLACE FUNCTION public.control_room_schedule_project_graph_ready_v1(p_run_key text)
RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path=public,pg_temp AS $$
declare
 v_graph public.control_room_project_graph_runs_v1%rowtype;
 v_node public.control_room_project_graph_nodes_v1%rowtype;
 v_limit integer; v_reserved integer; v_dispatched integer:=0;
 v_route jsonb; v_response jsonb; v_results jsonb:='[]'::jsonb;
 v_key text; v_input jsonb;
begin
 select * into v_graph from public.control_room_project_graph_runs_v1
 where run_key=p_run_key for update;
 if not found then raise exception 'graph_run_not_found'; end if;
 if v_graph.runtime_version<>2 then raise exception 'graph_runtime_version_mismatch'; end if;
 v_limit:=public.control_room_project_parallel_limit_v1(p_run_key);
 if v_limit is null then raise exception 'per6_contract_required'; end if;
 if v_graph.status in ('completed','failed','cancelled') then
   return jsonb_build_object('scheduled',0,'reason','terminal','results',v_results);
 end if;
 perform public.control_room_refresh_project_graph_v2(p_run_key);
 if (select status from public.control_room_project_graph_runs_v1 where run_key=p_run_key)<>'active' then
   return jsonb_build_object('scheduled',0,'reason','runtime_wait_or_stop','results',v_results);
 end if;
 -- One bounded readiness snapshot. Newly unlocked nodes are handled by a later tick.
 for v_node in
   select * from public.control_room_project_graph_nodes_v1
   where graph_run_key=p_run_key and status='ready'
   order by node_index,node_key limit 16
 loop
   exit when v_dispatched>=v_limit;
   if (select status from public.control_room_project_graph_runs_v1 where run_key=p_run_key)<>'active' then exit; end if;
   if v_node.authority_class<>'read_only'
      or v_node.execution_mode not in ('server_executable','deterministic_code') then
     v_results:=v_results||jsonb_build_array(jsonb_build_object('node_key',v_node.node_key,'status','not_read_only_executable'));
     continue;
   end if;
   -- A durable handoff already occupies a slot; never duplicate it.
   if exists(select 1 from public.control_room_project_graph_dispatches_v1
     where graph_run_key=p_run_key and node_id=v_node.id and status in ('awaiting_provider','executing')) then
     continue;
   end if;
   select count(*) into v_reserved from public.control_room_project_graph_nodes_v1 n
   where n.graph_run_key=p_run_key and (n.status in ('running','verifying') or
      exists(select 1 from public.control_room_project_graph_dispatches_v1 d
        where d.graph_run_key=p_run_key and d.node_id=n.id and d.status='awaiting_provider'));
   if v_reserved>=v_limit then exit; end if;
   v_route:=public.control_room_resolve_project_graph_dispatch_v1(p_run_key,v_node.node_key);
   if v_route->>'route_status'<>'dispatchable' then
     v_results:=v_results||jsonb_build_array(jsonb_build_object('node_key',v_node.node_key,'status','route_rejected','route',v_route));
     continue;
   end if;
   v_input:=coalesce(v_node.input_contract->'dispatch_input','{}'::jsonb);
   v_key:='per6:'||md5(p_run_key||':'||v_node.node_key||':'||v_node.attempt_count::text);
   v_response:=public.control_room_dispatch_project_graph_node_v1(p_run_key,v_node.node_key,v_key,v_input);
   v_results:=v_results||jsonb_build_array(jsonb_build_object('node_key',v_node.node_key,'dispatch',v_response->'dispatch'));
   v_dispatched:=v_dispatched+1;
 end loop;
 return jsonb_build_object('scheduled',v_dispatched,'max_parallel_nodes',v_limit,'results',v_results);
end $$;
REVOKE ALL ON FUNCTION public.control_room_schedule_project_graph_ready_v1(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.control_room_schedule_project_graph_ready_v1(text) TO service_role;
