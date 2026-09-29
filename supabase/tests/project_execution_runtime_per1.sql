-- Meterion Project Execution Runtime v1 — PER-1 regression canaries
-- Run in a privileged development/test database.
-- Every test is rolled back and must leave no rows behind.

begin;

do $$
declare
  v_state_version integer;
  v_rejected boolean := false;
  v_replay jsonb;
begin
  select (public.control_room_get_project_state_v3('ai-company-os')->>'state_version')::integer
  into v_state_version;

  -- Success path: dependency gating and terminal close.
  perform public.control_room_create_project_work_graph_v1(
    'ai-company-os',
    'per1-regression-success',
    'per1-regression-success',
    v_state_version,
    '{"objective":"PER-1 regression success","definition_of_done":{"criteria":["graph closes"]}}'::jsonb,
    '[
      {"node_key":"first-node","node_type":"code","action_kind":"test","purpose":"first","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"},
      {"node_key":"second-node","node_type":"verifier","action_kind":"test","purpose":"second","execution_mode":"server_executable","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"}
    ]'::jsonb,
    '[{"from":"first-node","to":"second-node","edge_kind":"control","required_status":"completed"}]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per1-regression-success'
      and node_key='first-node' and status='ready'
  ) then
    raise exception 'first_node_not_ready';
  end if;

  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per1-regression-success'
      and node_key='second-node' and status='waiting_dependency'
  ) then
    raise exception 'dependency_gate_failed';
  end if;

  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-success','first-node','ready','running',null,'{}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-success','first-node','running','completed','{"ok":true}'::jsonb,'{}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-success','second-node','ready','running',null,'{}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-success','second-node','running','verifying',null,'{}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-success','second-node','verifying','completed','{"ok":true}'::jsonb,'{}'::jsonb
  );

  if not exists (
    select 1
    from public.control_room_project_graph_runs_v1 g
    join public.control_room_run_envelopes r on r.run_key=g.run_key
    where g.run_key='per1-regression-success'
      and g.status='completed'
      and r.status='completed'
      and r.actions_used=2
      and r.resume_from is null
      and r.action_space='[]'::jsonb
  ) then
    raise exception 'success_graph_did_not_close';
  end if;

  -- Stale Project State rejection.
  begin
    perform public.control_room_create_project_work_graph_v1(
      'ai-company-os','per1-regression-stale','per1-regression-stale',
      greatest(v_state_version - 1, 0),
      '{"objective":"stale rejection"}'::jsonb,
      '[{"node_key":"stale-node","node_type":"code","action_kind":"test","purpose":"stale","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"}]'::jsonb,
      '[]'::jsonb,'{}'::jsonb
    );
  exception when others then
    if position('project_state_version_conflict' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;
  if not v_rejected then raise exception 'stale_state_not_rejected'; end if;

  -- Cycle rejection.
  v_rejected := false;
  begin
    perform public.control_room_create_project_work_graph_v1(
      'ai-company-os','per1-regression-cycle','per1-regression-cycle',v_state_version,
      '{"objective":"cycle rejection"}'::jsonb,
      '[
        {"node_key":"cycle-aa","node_type":"code","action_kind":"test","purpose":"a","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"},
        {"node_key":"cycle-bb","node_type":"code","action_kind":"test","purpose":"b","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"}
      ]'::jsonb,
      '[
        {"from":"cycle-aa","to":"cycle-bb","edge_kind":"control","required_status":"completed"},
        {"from":"cycle-bb","to":"cycle-aa","edge_kind":"control","required_status":"completed"}
      ]'::jsonb,
      '{}'::jsonb
    );
  exception when others then
    if position('graph_cycle_detected' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;
  if not v_rejected then raise exception 'cycle_not_rejected'; end if;

  -- Action budget enforcement.
  v_rejected := false;
  perform public.control_room_create_project_work_graph_v1(
    'ai-company-os','per1-regression-actions','per1-regression-actions',v_state_version,
    '{"objective":"action budget"}'::jsonb,
    '[
      {"node_key":"action-one","node_type":"code","action_kind":"test","purpose":"one","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"},
      {"node_key":"action-two","node_type":"code","action_kind":"test","purpose":"two","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"}
    ]'::jsonb,
    '[{"from":"action-one","to":"action-two","edge_kind":"control","required_status":"completed"}]'::jsonb,
    '{"max_actions":1,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-actions','action-one','ready','running',null,'{}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-actions','action-one','running','completed','{"ok":true}'::jsonb,'{}'::jsonb
  );
  if not exists (
    select 1
    from public.control_room_project_graph_runs_v1 g
    join public.control_room_run_envelopes r on r.run_key=g.run_key
    where g.run_key='per1-regression-actions'
      and g.status='failed'
      and r.status='blocked'
      and r.stop_reason='action_budget_exhausted'
      and r.resume_from is null
      and r.action_space='[]'::jsonb
  ) then
    raise exception 'action_budget_stop_not_materialized';
  end if;

  begin
    perform public.control_room_transition_project_graph_node_v1(
      'per1-regression-actions','action-two','ready','running',null,'{}'::jsonb
    );
  exception when others then
    if position('graph_run_not_executable:failed' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'failed_graph_remained_executable'; end if;

  -- Retry budget enforcement.
  v_rejected := false;
  perform public.control_room_create_project_work_graph_v1(
    'ai-company-os','per1-regression-retries','per1-regression-retries',v_state_version,
    '{"objective":"retry budget"}'::jsonb,
    '[{"node_key":"retry-node","node_type":"verifier","action_kind":"test","purpose":"retry","execution_mode":"server_executable","failure_policy":"retry","max_attempts":2,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-retries','retry-node','ready','running',null,'{}'::jsonb
  );
  perform public.control_room_transition_project_graph_node_v1(
    'per1-regression-retries','retry-node','running','failed','{"expected":true}'::jsonb,'{}'::jsonb
  );
  if not exists (
    select 1
    from public.control_room_project_graph_runs_v1 g
    join public.control_room_run_envelopes r on r.run_key=g.run_key
    where g.run_key='per1-regression-retries'
      and g.status='failed'
      and r.status='blocked'
      and r.stop_reason='retry_budget_exhausted'
      and r.resume_from is null
      and r.action_space='[]'::jsonb
  ) then
    raise exception 'retry_budget_stop_not_materialized';
  end if;

  begin
    perform public.control_room_retry_project_graph_node_v1(
      'per1-regression-retries','retry-node'
    );
  exception when others then
    if position('run retry budget exceeded' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'retry_budget_not_enforced'; end if;

  -- Idempotent create replay must survive a later Project State version.
  perform public.control_room_patch_project_state_v1(
    'ai-company-os',
    v_state_version,
    jsonb_build_object(
      'current_focus', 'PER-1 idempotency rollback probe',
      'verified_at', now()::text,
      'source_type', 'per1-regression'
    )
  );

  select public.control_room_create_project_work_graph_v1(
    'ai-company-os',
    'per1-regression-success',
    'per1-regression-success',
    v_state_version,
    '{"objective":"PER-1 regression success","definition_of_done":{"criteria":["graph closes"]}}'::jsonb,
    '[
      {"node_key":"first-node","node_type":"code","action_kind":"test","purpose":"first","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"},
      {"node_key":"second-node","node_type":"verifier","action_kind":"test","purpose":"second","execution_mode":"server_executable","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"}
    ]'::jsonb,
    '[{"from":"first-node","to":"second-node","edge_kind":"control","required_status":"completed"}]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  ) into v_replay;

  if coalesce((v_replay->>'idempotent_replay')::boolean, false) is not true then
    raise exception 'idempotent_replay_failed_after_state_advance';
  end if;

  -- Same run key with changed limits is not the same request.
  v_rejected := false;
  begin
    perform public.control_room_create_project_work_graph_v1(
      'ai-company-os',
      'per1-regression-success',
      'per1-regression-success',
      v_state_version,
      '{"objective":"PER-1 regression success","definition_of_done":{"criteria":["graph closes"]}}'::jsonb,
      '[
        {"node_key":"first-node","node_type":"code","action_kind":"test","purpose":"first","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"},
        {"node_key":"second-node","node_type":"verifier","action_kind":"test","purpose":"second","execution_mode":"server_executable","failure_policy":"stop","max_attempts":1,"authority_class":"read_only"}
      ]'::jsonb,
      '[{"from":"first-node","to":"second-node","edge_kind":"control","required_status":"completed"}]'::jsonb,
      '{"max_actions":3,"max_retries":0,"max_spend_microusd":0}'::jsonb
    );
  exception when others then
    if position('graph_run_limits_conflict' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'run_limit_conflict_not_rejected'; end if;
end $$;

rollback;
