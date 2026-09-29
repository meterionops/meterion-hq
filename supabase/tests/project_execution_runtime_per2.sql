-- Meterion Project Execution Runtime v1 — PER-2 rollback regression suite
-- Runs against a privileged Control Room database and leaves no persistent rows.

begin;

do $$
declare
  v_state integer;
  v_claim jsonb;
  v_runtime jsonb;
  v_token uuid;
  v_rejected boolean;
  v_actions integer;
begin
  select (public.control_room_get_project_state_v3('ai-company-os')->>'state_version')::integer
    into v_state;

  ---------------------------------------------------------------------------
  -- A. Interruption after one verified node: only the interrupted node replays.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per2-regression-interrupt','per2-regression-interrupt',v_state,
    '{"objective":"PER-2 interruption regression","compiler_version":"per2"}'::jsonb,
    '[
      {"node_key":"verified-first","node_type":"code","action_kind":"test","purpose":"verified first","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":1,"timeout_seconds":10,"authority_class":"read_only"},
      {"node_key":"interrupted-second","node_type":"code","action_kind":"test","purpose":"interrupt and resume","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":2,"timeout_seconds":10,"authority_class":"read_only","recovery_policy":"retry"}
    ]'::jsonb,
    '[{"from":"verified-first","to":"interrupted-second","edge_kind":"control","required_status":"completed"}]'::jsonb,
    '{"max_actions":5,"max_retries":1,"max_spend_microusd":0}'::jsonb
  );

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-interrupt','verified-first','reg-int:first:claim',5
  );
  v_token := (v_claim->'claim'->>'lease_token')::uuid;
  perform public.control_room_transition_project_graph_node_v2(
    'per2-regression-interrupt','verified-first','reg-int:first:complete',
    'running','completed',v_token,'{"ok":true}'::jsonb,'{}'::jsonb,'{}'::jsonb
  );

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-interrupt','interrupted-second','reg-int:second:claim1',1
  );
  perform pg_sleep(1.1);

  v_runtime := public.control_room_refresh_project_graph_v2('per2-regression-interrupt');
  if v_runtime->'run_envelope'->>'stop_reason' <> 'stale_execution_wake_required' then
    raise exception 'stale_execution_not_detected';
  end if;

  v_runtime := public.control_room_wake_project_graph_v2(
    'per2-regression-interrupt','reg-int:wake1'
  );

  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per2-regression-interrupt'
      and node_key='verified-first'
      and status='completed'
      and attempt_count=1
  ) then raise exception 'verified_node_changed'; end if;

  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per2-regression-interrupt'
      and node_key='interrupted-second'
      and status='ready'
      and attempt_count=1
      and interruption_count=1
      and execution_token is null
  ) then raise exception 'interrupted_node_not_requeued'; end if;

  if (select retries_used from public.control_room_run_envelopes where run_key='per2-regression-interrupt') <> 1 then
    raise exception 'stale_recovery_retry_budget_not_consumed';
  end if;

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-interrupt','interrupted-second','reg-int:second:claim2',5
  );
  v_token := (v_claim->'claim'->>'lease_token')::uuid;
  perform public.control_room_transition_project_graph_node_v2(
    'per2-regression-interrupt','interrupted-second','reg-int:second:complete',
    'running','completed',v_token,'{"ok":true}'::jsonb,'{}'::jsonb,'{}'::jsonb
  );

  if not exists (
    select 1 from public.control_room_project_graph_runs_v1
    where run_key='per2-regression-interrupt' and status='completed'
  ) then raise exception 'interruption_graph_not_completed'; end if;

  ---------------------------------------------------------------------------
  -- A2. Stale safe-retry recovery fails closed when Run Envelope retry budget is zero.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per2-regression-retry-budget','per2-regression-retry-budget',v_state,
    '{"objective":"PER-2 stale retry budget regression","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"budget-node","node_type":"code","action_kind":"test","purpose":"retry budget","execution_mode":"deterministic_code","failure_policy":"stop","max_attempts":2,"timeout_seconds":10,"authority_class":"read_only","recovery_policy":"retry"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":3,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-retry-budget','budget-node','reg-budget:claim1',1
  );
  perform pg_sleep(1.1);
  perform public.control_room_refresh_project_graph_v2('per2-regression-retry-budget');
  v_runtime := public.control_room_wake_project_graph_v2(
    'per2-regression-retry-budget','reg-budget:wake1'
  );

  if v_runtime->'graph_run'->>'status' <> 'failed'
     or v_runtime->'run_envelope'->>'status' <> 'blocked' then
    raise exception 'stale_retry_budget_did_not_fail_closed';
  end if;

  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per2-regression-retry-budget'
      and node_key='budget-node'
      and status='failed'
      and attempt_count=1
      and interruption_count=1
  ) then raise exception 'stale_retry_budget_node_not_failed'; end if;

  if not exists (
    select 1 from public.control_room_project_graph_exceptions_v1
    where graph_run_key='per2-regression-retry-budget'
      and code='stale_execution_retry_budget_exhausted'
      and severity='blocker'
      and status='open'
  ) then raise exception 'stale_retry_budget_exception_missing'; end if;

  if (select retries_used from public.control_room_run_envelopes where run_key='per2-regression-retry-budget') <> 0 then
    raise exception 'exhausted_retry_budget_was_incremented';
  end if;

  ---------------------------------------------------------------------------
  -- B. Verification resume + write reconciliation do not re-execute effects.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per2-regression-reconcile','per2-regression-reconcile',v_state,
    '{"objective":"PER-2 reconcile regression","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"write-node","node_type":"tool","action_kind":"test.write","purpose":"write once","execution_mode":"server_executable","failure_policy":"stop","max_attempts":2,"timeout_seconds":10,"authority_class":"bounded_write"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":3,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-reconcile','write-node','reg-rec:claim1',1
  );
  perform pg_sleep(1.1);
  perform public.control_room_refresh_project_graph_v2('per2-regression-reconcile');
  v_runtime := public.control_room_wake_project_graph_v2(
    'per2-regression-reconcile','reg-rec:wake1'
  );

  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per2-regression-reconcile'
      and node_key='write-node'
      and recovery_policy='reconcile'
      and status='verifying'
      and attempt_count=1
      and interruption_count=1
      and execution_token is null
  ) then raise exception 'bounded_write_not_reconcile_only'; end if;

  if not exists (
    select 1 from public.control_room_project_graph_exceptions_v1
    where graph_run_key='per2-regression-reconcile'
      and code='stale_execution_reconcile'
      and status='open'
  ) then raise exception 'reconcile_exception_missing'; end if;

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-reconcile','write-node','reg-rec:claim2',5
  );
  if v_claim->'claim'->>'phase' <> 'reconcile' then
    raise exception 'reconcile_phase_missing';
  end if;
  v_token := (v_claim->'claim'->>'lease_token')::uuid;

  select actions_used into v_actions
  from public.control_room_run_envelopes
  where run_key='per2-regression-reconcile';
  if v_actions <> 1 then raise exception 'reconcile_reexecuted_effect:%',v_actions; end if;

  perform public.control_room_transition_project_graph_node_v2(
    'per2-regression-reconcile','write-node','reg-rec:complete',
    'verifying','completed',v_token,
    '{"effect_found":true}'::jsonb,'{"reconciled_present":true}'::jsonb,'{}'::jsonb
  );

  if exists (
    select 1 from public.control_room_project_graph_exceptions_v1
    where graph_run_key='per2-regression-reconcile' and status='open'
  ) then raise exception 'reconcile_exception_not_resolved'; end if;

  ---------------------------------------------------------------------------
  -- C. Durable session/Owner waits and explicit releases.
  ---------------------------------------------------------------------------
  v_runtime := public.control_room_create_project_work_graph_v2(
    'ai-company-os','per2-regression-session','per2-regression-session',v_state,
    '{"objective":"PER-2 session wait regression","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"session-node","node_type":"worker","action_kind":"session.test","purpose":"session wait","execution_mode":"chatgpt_session","failure_policy":"stop","max_attempts":1,"timeout_seconds":30,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,'{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  if v_runtime->'run_envelope'->>'stop_reason' <> 'waiting_session'
     or v_runtime->'run_envelope'->>'resume_from' <> 'session-node' then
    raise exception 'session_wait_not_exposed';
  end if;
  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per2-regression-session'
      and status='waiting_session'
      and wait_context->>'reason'='chatgpt_session_required'
      and wait_started_at is not null
  ) then raise exception 'session_wait_context_missing'; end if;

  perform public.control_room_transition_project_graph_node_v2(
    'per2-regression-session','session-node','reg-session:release',
    'waiting_session','ready',null,null,'{"session_available":true}'::jsonb,'{}'::jsonb
  );

  v_runtime := public.control_room_create_project_work_graph_v2(
    'ai-company-os','per2-regression-owner','per2-regression-owner',v_state,
    '{"objective":"PER-2 Owner wait regression","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"owner-node","node_type":"human_gate","action_kind":"owner.test","purpose":"owner wait","execution_mode":"human_gate","failure_policy":"stop","max_attempts":1,"timeout_seconds":30,"authority_class":"owner_gate"}]'::jsonb,
    '[]'::jsonb,'{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  if v_runtime->'run_envelope'->>'stop_reason' <> 'waiting_owner'
     or v_runtime->'run_envelope'->>'resume_from' <> 'owner-node' then
    raise exception 'owner_wait_not_exposed';
  end if;
  if not exists (
    select 1 from public.control_room_project_graph_nodes_v1
    where graph_run_key='per2-regression-owner'
      and status='waiting_owner'
      and wait_context->>'reason'='owner_gate_required'
      and wait_started_at is not null
  ) then raise exception 'owner_wait_context_missing'; end if;

  ---------------------------------------------------------------------------
  -- D. Idempotency + retry + legacy guards.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per2-regression-guard','per2-regression-guard',v_state,
    '{"objective":"PER-2 guard regression","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"guard-node","node_type":"worker","action_kind":"retry.test","purpose":"guard","execution_mode":"server_executable","failure_policy":"retry","max_attempts":2,"timeout_seconds":10,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,'{"max_actions":4,"max_retries":1,"max_spend_microusd":0}'::jsonb
  );

  v_rejected := false;
  begin
    perform public.control_room_refresh_project_graph_v1('per2-regression-guard');
  exception when others then
    if position('per2_runtime_requires_v2_refresh' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'legacy_refresh_not_guarded'; end if;

  v_rejected := false;
  begin
    perform public.control_room_transition_project_graph_node_v1(
      'per2-regression-guard','guard-node','ready','running',null,'{}'::jsonb
    );
  exception when others then
    if position('per2_runtime_requires_v2_transition' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'legacy_transition_not_guarded'; end if;

  v_claim := public.control_room_claim_project_graph_node_v2(
    'per2-regression-guard','guard-node','reg-guard:claim1',5
  );
  v_token := (v_claim->'claim'->>'lease_token')::uuid;

  v_runtime := public.control_room_claim_project_graph_node_v2(
    'per2-regression-guard','guard-node','reg-guard:claim1',5
  );
  if coalesce((v_runtime->>'idempotent_transition_replay')::boolean,false) is not true then
    raise exception 'claim_replay_not_idempotent';
  end if;

  perform public.control_room_transition_project_graph_node_v2(
    'per2-regression-guard','guard-node','reg-guard:fail1',
    'running','failed',v_token,'{"error":"expected"}'::jsonb,'{}'::jsonb,'{}'::jsonb
  );

  v_rejected := false;
  begin
    perform public.control_room_transition_project_graph_node_v2(
      'per2-regression-guard','guard-node','reg-guard:fail1',
      'running','failed',v_token,'{"error":"different"}'::jsonb,'{}'::jsonb,'{}'::jsonb
    );
  exception when others then
    if position('transition_key_conflict' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'transition_key_conflict_not_enforced'; end if;

  v_rejected := false;
  begin
    perform public.control_room_retry_project_graph_node_v1(
      'per2-regression-guard','guard-node'
    );
  exception when others then
    if position('per2_runtime_requires_v2_retry' in sqlerrm) > 0 then v_rejected := true; else raise; end if;
  end;
  if not v_rejected then raise exception 'legacy_retry_not_guarded'; end if;

  v_runtime := public.control_room_retry_project_graph_node_v2(
    'per2-regression-guard','guard-node','reg-guard:retry1','{}'::jsonb
  );
  if (v_runtime->'run_envelope'->>'retries_used')::integer <> 1 then
    raise exception 'retry_budget_not_consumed';
  end if;

  v_runtime := public.control_room_retry_project_graph_node_v2(
    'per2-regression-guard','guard-node','reg-guard:retry1','{}'::jsonb
  );
  if coalesce((v_runtime->>'idempotent_transition_replay')::boolean,false) is not true then
    raise exception 'retry_replay_not_idempotent';
  end if;
end $$;

-- Security boundary: new RPCs are service-role only.
do $$
begin
  if has_function_privilege('anon','public.control_room_wake_project_graph_v2(text,text)','EXECUTE')
     or has_function_privilege('authenticated','public.control_room_wake_project_graph_v2(text,text)','EXECUTE')
     or not has_function_privilege('service_role','public.control_room_wake_project_graph_v2(text,text)','EXECUTE') then
    raise exception 'wake_rpc_privilege_boundary_failed';
  end if;

  if exists (
    select 1 from information_schema.table_privileges
    where table_schema='public'
      and table_name in (
        'control_room_project_graph_node_transitions_v2',
        'control_room_project_graph_exceptions_v1',
        'control_room_project_graph_wakes_v2'
      )
      and grantee in ('anon','authenticated')
  ) then
    raise exception 'per2_table_privilege_boundary_failed';
  end if;
end $$;

rollback;
