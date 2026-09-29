-- Meterion Project Execution Runtime v1 — PER-3 rollback regression suite
-- Requires the PER-3 dispatch core migration. Leaves no persistent test rows.

begin;

do $$
declare
  v_state integer := 6;
  v_route jsonb;
  v_out jsonb;
  v_rejected boolean;
  v_project_id uuid;
begin
  ---------------------------------------------------------------------------
  -- A. Successful declared capability dispatch + idempotent replay.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-success',
    'per3-regression-success',
    v_state,
    '{"objective":"PER-3 successful declared capability dispatch","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"read-state",
      "node_type":"tool",
      "action_kind":"control_room.project_state.read",
      "purpose":"Read canonical Project State through PER-3 dispatch.",
      "execution_mode":"server_executable",
      "required_capability":"control_room.project_state.read",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"read_only"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":3,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_route := public.control_room_resolve_project_graph_dispatch_v1(
    'per3-regression-success','read-state'
  );

  if v_route->>'route_status' <> 'dispatchable'
     or v_route->>'required_capability' <> 'control_room.project_state.read'
     or v_route->>'executor_key' <> 'control_room.project_state.read.v1'
     or v_route->>'phase' <> 'execute' then
    raise exception 'success_route_not_resolved:%',v_route;
  end if;

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-success','read-state','per3-reg-success:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'completed' then
    raise exception 'success_dispatch_not_completed:%',v_out->'dispatch';
  end if;

  if (v_out->'dispatch'->'result'->'project_state'->>'state_version')::integer <> v_state then
    raise exception 'success_dispatch_wrong_project_state';
  end if;

  if not exists (
    select 1
    from public.control_room_project_graph_nodes_v1
    where graph_run_key='per3-regression-success'
      and node_key='read-state'
      and status='completed'
      and attempt_count=1
      and result->'project_state'->>'project_key'='ai-company-os'
      and evidence->'dispatch'->>'capability_key'='control_room.project_state.read'
      and evidence->'dispatch'->>'executor_key'='control_room.project_state.read.v1'
  ) then
    raise exception 'success_node_result_or_evidence_missing';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-success') <> 1 then
    raise exception 'success_action_budget_wrong';
  end if;

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-success','read-state','per3-reg-success:dispatch','{}'::jsonb
  );

  if coalesce((v_out->>'idempotent_dispatch_replay')::boolean,false) is not true then
    raise exception 'success_dispatch_replay_not_idempotent';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-success') <> 1 then
    raise exception 'dispatch_replay_consumed_action';
  end if;

  v_rejected := false;
  begin
    perform public.control_room_dispatch_project_graph_node_v1(
      'per3-regression-success','read-state','per3-reg-success:dispatch','{"changed":true}'::jsonb
    );
  exception when others then
    if position('dispatch_key_conflict' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;

  if not v_rejected then
    raise exception 'dispatch_key_conflict_not_enforced';
  end if;

  ---------------------------------------------------------------------------
  -- B. Unregistered capability fails closed without action or attempt.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-unsupported',
    'per3-regression-unsupported',
    v_state,
    '{"objective":"PER-3 unsupported capability rejection","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"unsupported",
      "node_type":"tool",
      "action_kind":"control_room.unknown",
      "purpose":"Prove unregistered capability fails closed.",
      "execution_mode":"server_executable",
      "required_capability":"control_room.unknown",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"read_only"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-unsupported','unsupported','per3-reg-unsupported:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'rejected'
     or v_out->'dispatch'->'route'->>'error_code' <> 'capability_not_registered' then
    raise exception 'unsupported_capability_not_rejected:%',v_out->'dispatch';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-unsupported') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per3-regression-unsupported' and node_key='unsupported') <> 0 then
    raise exception 'unsupported_capability_consumed_budget';
  end if;

  ---------------------------------------------------------------------------
  -- C. Capability authority ceiling is enforced before node claim.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-authority',
    'per3-regression-authority',
    v_state,
    '{"objective":"PER-3 authority rejection","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"too-much-authority",
      "node_type":"tool",
      "action_kind":"control_room.project_state.read",
      "purpose":"Prove authority ceiling is enforced before claim.",
      "execution_mode":"server_executable",
      "required_capability":"control_room.project_state.read",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"prepare"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-authority','too-much-authority','per3-reg-authority:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'rejected'
     or v_out->'dispatch'->'route'->>'error_code' <> 'capability_authority_exceeded' then
    raise exception 'authority_not_rejected:%',v_out->'dispatch';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-authority') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per3-regression-authority' and node_key='too-much-authority') <> 0 then
    raise exception 'authority_rejection_consumed_budget';
  end if;

  ---------------------------------------------------------------------------
  -- D. ChatGPT-session work is a durable wait, never server-dispatched.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-session',
    'per3-regression-session',
    v_state,
    '{"objective":"PER-3 session wait","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"session-node",
      "node_type":"worker",
      "action_kind":"session.required",
      "purpose":"Prove session-required work is not server-dispatched.",
      "execution_mode":"chatgpt_session",
      "required_capability":"control_room.project_state.read",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"read_only"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-session','session-node','per3-reg-session:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'waiting'
     or v_out->'dispatch'->'route'->>'route_status' <> 'waiting_session'
     or v_out->'dispatch'->'route'->>'error_code' <> 'chatgpt_session_required' then
    raise exception 'session_route_not_waiting:%',v_out->'dispatch';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-session') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per3-regression-session' and node_key='session-node') <> 0 then
    raise exception 'session_wait_consumed_budget';
  end if;

  ---------------------------------------------------------------------------
  -- E. Human/Owner work is a durable Owner wait.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-owner',
    'per3-regression-owner',
    v_state,
    '{"objective":"PER-3 owner wait","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"owner-node",
      "node_type":"human_gate",
      "action_kind":"owner.required",
      "purpose":"Prove Owner-gated work is not server-dispatched.",
      "execution_mode":"human_gate",
      "required_capability":"control_room.project_state.read",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"owner_gate"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-owner','owner-node','per3-reg-owner:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'waiting'
     or v_out->'dispatch'->'route'->>'route_status' <> 'waiting_owner'
     or v_out->'dispatch'->'route'->>'error_code' <> 'owner_gate_required' then
    raise exception 'owner_route_not_waiting:%',v_out->'dispatch';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-owner') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per3-regression-owner' and node_key='owner-node') <> 0 then
    raise exception 'owner_wait_consumed_budget';
  end if;

  ---------------------------------------------------------------------------
  -- F. Disabled project binding rejects before claim.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-binding',
    'per3-regression-binding',
    v_state,
    '{"objective":"PER-3 project binding enforcement","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"binding-node",
      "node_type":"tool",
      "action_kind":"control_room.project_state.read",
      "purpose":"Prove disabled project capability binding fails closed.",
      "execution_mode":"server_executable",
      "required_capability":"control_room.project_state.read",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"read_only"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  update public.control_room_project_capability_bindings_v1 b
  set status='disabled', updated_at=now()
  from public.control_room_projects p
  where b.project_id=p.id
    and p.project_key='ai-company-os'
    and b.capability_key='control_room.project_state.read';

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-binding','binding-node','per3-reg-binding:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'rejected'
     or v_out->'dispatch'->'route'->>'error_code' <> 'capability_binding_disabled' then
    raise exception 'disabled_binding_not_rejected:%',v_out->'dispatch';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per3-regression-binding') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per3-regression-binding' and node_key='binding-node') <> 0 then
    raise exception 'disabled_binding_consumed_budget';
  end if;

  update public.control_room_project_capability_bindings_v1 b
  set status='active', updated_at=now()
  from public.control_room_projects p
  where b.project_id=p.id
    and p.project_key='ai-company-os'
    and b.capability_key='control_room.project_state.read';

  ---------------------------------------------------------------------------
  -- G. Run action budget is checked before node claim.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per3-regression-budget',
    'per3-regression-budget',
    v_state,
    '{"objective":"PER-3 preflight budget rejection","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"budget-node",
      "node_type":"tool",
      "action_kind":"control_room.project_state.read",
      "purpose":"Prove action budget is checked before dispatch.",
      "execution_mode":"server_executable",
      "required_capability":"control_room.project_state.read",
      "failure_policy":"stop",
      "max_attempts":1,
      "timeout_seconds":30,
      "authority_class":"read_only"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":1,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  select project_id into v_project_id
  from public.control_room_project_graph_runs_v1
  where run_key='per3-regression-budget';

  perform public.control_room_checkpoint_run_v1(
    'per3-regression-budget',
    v_project_id,
    'active',
    'active',
    1,0,0,0,
    null,null,null,null,null,null
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per3-regression-budget','budget-node','per3-reg-budget:dispatch','{}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'rejected'
     or v_out->'dispatch'->'route'->>'error_code' <> 'action_budget_exhausted' then
    raise exception 'budget_not_rejected_before_claim:%',v_out->'dispatch';
  end if;

  if (select attempt_count from public.control_room_project_graph_nodes_v1
      where graph_run_key='per3-regression-budget' and node_key='budget-node') <> 0 then
    raise exception 'budget_rejection_consumed_attempt';
  end if;

  ---------------------------------------------------------------------------
  -- H. Builtin executor surface is closed: arbitrary executor keys fail.
  ---------------------------------------------------------------------------
  v_rejected := false;
  begin
    perform public.control_room_execute_builtin_capability_v1(
      'control_room.arbitrary.function',
      (select id from public.control_room_projects where project_key='ai-company-os'),
      '{}'::jsonb
    );
  exception when others then
    if position('builtin_executor_not_supported' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;

  if not v_rejected then
    raise exception 'arbitrary_builtin_executor_not_rejected';
  end if;
end $$;

-- Security boundary.
do $$
begin
  if has_function_privilege('anon','public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)','EXECUTE')
     or has_function_privilege('authenticated','public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)','EXECUTE')
     or not has_function_privilege('service_role','public.control_room_dispatch_project_graph_node_v1(text,text,text,jsonb)','EXECUTE') then
    raise exception 'dispatch_rpc_privilege_boundary_failed';
  end if;

  if has_function_privilege('anon','public.control_room_resolve_project_graph_dispatch_v1(text,text)','EXECUTE')
     or has_function_privilege('authenticated','public.control_room_resolve_project_graph_dispatch_v1(text,text)','EXECUTE')
     or not has_function_privilege('service_role','public.control_room_resolve_project_graph_dispatch_v1(text,text)','EXECUTE') then
    raise exception 'resolve_rpc_privilege_boundary_failed';
  end if;

  if exists (
    select 1
    from information_schema.table_privileges
    where table_schema='public'
      and table_name in (
        'control_room_execution_executors_v1',
        'control_room_execution_capabilities_v1',
        'control_room_project_capability_bindings_v1',
        'control_room_project_graph_dispatches_v1'
      )
      and grantee in ('anon','authenticated')
  ) then
    raise exception 'per3_table_privilege_boundary_failed';
  end if;
end $$;

rollback;
