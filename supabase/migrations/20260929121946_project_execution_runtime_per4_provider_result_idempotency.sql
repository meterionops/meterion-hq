begin;

drop function if exists public.control_room_assert_provider_finish_payload_v1(
  text,jsonb,jsonb,jsonb,text,text,text
);

CREATE OR REPLACE FUNCTION public.control_room_assert_provider_finish_payload_v1(p_capability_key text, p_dispatch_input jsonb, p_result jsonb, p_provider_evidence jsonb, p_provider_adapter_key text, p_provider_operation text, p_provider_invocation_key text, p_success boolean)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.control_room_claim_project_graph_provider_dispatch_v1(p_run_key text, p_dispatch_key text, p_claim_key text, p_lease_seconds integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.control_room_finish_project_graph_provider_dispatch_v1(p_run_key text, p_dispatch_key text, p_finish_key text, p_lease_token uuid, p_success boolean, p_result jsonb DEFAULT '{}'::jsonb, p_provider_evidence jsonb DEFAULT '{}'::jsonb, p_error_code text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
$function$;

revoke all on function public.control_room_assert_provider_finish_payload_v1(
  text,jsonb,jsonb,jsonb,text,text,text,boolean
) from public,anon,authenticated,service_role;
revoke all on function public.control_room_claim_project_graph_provider_dispatch_v1(
  text,text,text,integer
) from public,anon,authenticated,service_role;
revoke all on function public.control_room_finish_project_graph_provider_dispatch_v1(
  text,text,text,uuid,boolean,jsonb,jsonb,text
) from public,anon,authenticated,service_role;

grant execute on function public.control_room_assert_provider_finish_payload_v1(
  text,jsonb,jsonb,jsonb,text,text,text,boolean
) to service_role;
grant execute on function public.control_room_claim_project_graph_provider_dispatch_v1(
  text,text,text,integer
) to service_role;
grant execute on function public.control_room_finish_project_graph_provider_dispatch_v1(
  text,text,text,uuid,boolean,jsonb,jsonb,text
) to service_role;

commit;