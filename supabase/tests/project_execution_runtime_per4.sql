-- Meterion Project Execution Runtime v1 — PER-4 rollback regression suite
-- Requires the PER-4 provider adapter migration. Leaves no persistent test rows.

begin;

do $$
declare
  v_state integer;
  v_out jsonb;
  v_claim jsonb;
  v_finish jsonb;
  v_token uuid;
  v_invocation text;
  v_rejected boolean;
begin
  v_state := (public.control_room_get_project_state_v3('ai-company-os')->>'state_version')::integer;

  ---------------------------------------------------------------------------
  -- A. Success + prepare/claim/finish replay + changed-request conflict.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-success','per4-regression-success',v_state,
    '{"objective":"PER-4 provider success","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Read repository metadata through the provider bridge.",
       "execution_mode":"server_executable","required_capability":"github.repository.read",
       "failure_policy":"retry","max_attempts":2,"timeout_seconds":120,
       "authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":3,"max_retries":1,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-success','github-read','per4-reg-success:dispatch',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );
  v_invocation := v_out->'dispatch'->'provider_handoff'->>'provider_invocation_key';

  if v_out->'dispatch'->>'status' <> 'awaiting_provider'
     or v_out->'dispatch'->'provider_handoff'->>'provider_adapter_key' <> 'github.connector.read.v1'
     or v_out->'dispatch'->'provider_handoff'->>'provider_operation' <> 'get_repo'
     or v_out->'dispatch'->'provider_handoff'->>'credential_mode' <> 'connector_managed'
     or v_invocation is null then
    raise exception 'per4_success_handoff_wrong:%',v_out->'dispatch';
  end if;

  if (select actions_used from public.control_room_run_envelopes where run_key='per4-regression-success') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per4-regression-success' and node_key='github-read') <> 0 then
    raise exception 'per4_prepare_consumed_budget';
  end if;

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-success','github-read','per4-reg-success:dispatch',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );
  if coalesce((v_out->>'idempotent_dispatch_replay')::boolean,false) is not true then
    raise exception 'per4_prepare_replay_not_idempotent';
  end if;

  v_rejected := false;
  begin
    perform public.control_room_dispatch_project_graph_node_v1(
      'per4-regression-success','github-read','per4-reg-success:dispatch',
      '{"repository_full_name":"meterionops/not-the-same"}'::jsonb
    );
  exception when others then
    if position('dispatch_key_conflict' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;
  if not v_rejected then
    raise exception 'per4_changed_dispatch_not_rejected';
  end if;

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-success','per4-reg-success:dispatch','per4-reg-success:claim',120
  );
  v_token := (v_claim->'provider_claim'->>'lease_token')::uuid;

  if v_claim->'provider_claim'->>'status' <> 'executing'
     or (select actions_used from public.control_room_run_envelopes where run_key='per4-regression-success') <> 1
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per4-regression-success' and node_key='github-read') <> 1 then
    raise exception 'per4_claim_wrong';
  end if;

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-success','per4-reg-success:dispatch','per4-reg-success:claim',120
  );
  if coalesce((v_claim->>'idempotent_provider_claim_replay')::boolean,false) is not true then
    raise exception 'per4_claim_replay_not_idempotent';
  end if;

  v_finish := public.control_room_finish_project_graph_provider_dispatch_v1(
    'per4-regression-success','per4-reg-success:dispatch','per4-reg-success:finish',
    v_token,true,
    '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","visibility":"public","archived":false,"disabled":null,"provider_observed_at":"2026-09-29T12:00:00Z"}'::jsonb,
    jsonb_build_object(
      'provider','github',
      'adapter_key','github.connector.read.v1',
      'operation','get_repo',
      'provider_invocation_key',v_invocation,
      'credential_mode','connector_managed',
      'source_ref','github:repository:meterionops/meterion-hq',
      'returned_by','connected_github_provider'
    ),
    null
  );

  if v_finish->'provider_finish'->>'success' <> 'true' then
    raise exception 'per4_finish_not_success';
  end if;

  v_finish := public.control_room_finish_project_graph_provider_dispatch_v1(
    'per4-regression-success','per4-reg-success:dispatch','per4-reg-success:finish',
    v_token,true,
    '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","visibility":"public","archived":false,"disabled":null,"provider_observed_at":"2026-09-29T12:00:00Z"}'::jsonb,
    jsonb_build_object(
      'provider','github',
      'adapter_key','github.connector.read.v1',
      'operation','get_repo',
      'provider_invocation_key',v_invocation,
      'credential_mode','connector_managed',
      'source_ref','github:repository:meterionops/meterion-hq',
      'returned_by','connected_github_provider'
    ),
    null
  );

  if coalesce((v_finish->>'idempotent_provider_finish_replay')::boolean,false) is not true then
    raise exception 'per4_finish_replay_not_idempotent';
  end if;

  if exists (
    select 1
    from public.control_room_project_graph_dispatches_v1
    where graph_run_key='per4-regression-success'
      and (
        public.control_room_provider_payload_has_secret_keys_v1(input)
        or public.control_room_provider_payload_has_secret_keys_v1(result)
        or public.control_room_provider_payload_has_secret_keys_v1(evidence)
      )
  ) then
    raise exception 'per4_provider_credential_material_persisted';
  end if;

  ---------------------------------------------------------------------------
  -- B. Secret-bearing input is rejected before dispatch persistence or claim.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-secret','per4-regression-secret',v_state,
    '{"objective":"PER-4 secret reject","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Reject provider secret input.","execution_mode":"server_executable",
       "required_capability":"github.repository.read","failure_policy":"stop",
       "max_attempts":1,"timeout_seconds":60,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_rejected := false;
  begin
    perform public.control_room_dispatch_project_graph_node_v1(
      'per4-regression-secret','github-read','per4-reg-secret:dispatch',
      '{"repository_full_name":"meterionops/meterion-hq","api_key":"must-not-enter-runtime"}'::jsonb
    );
  exception when others then
    if position('dispatch_payload_secret_key_rejected' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;

  if not v_rejected
     or (select actions_used from public.control_room_run_envelopes where run_key='per4-regression-secret') <> 0
     or exists (
       select 1 from public.control_room_project_graph_dispatches_v1
       where graph_run_key='per4-regression-secret'
     ) then
    raise exception 'per4_secret_input_boundary_failed';
  end if;

  ---------------------------------------------------------------------------
  -- C. Project allowlist is enforced before claim.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-allowlist','per4-regression-allowlist',v_state,
    '{"objective":"PER-4 allowlist reject","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Reject repository outside project binding.","execution_mode":"server_executable",
       "required_capability":"github.repository.read","failure_policy":"stop",
       "max_attempts":1,"timeout_seconds":60,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-allowlist','github-read','per4-reg-allowlist:dispatch',
    '{"repository_full_name":"openai/openai-python"}'::jsonb
  );

  if v_out->'dispatch'->>'status' <> 'rejected'
     or v_out->'dispatch'->'provider_input'->>'error_code' <> 'github_repository_not_allowed' then
    raise exception 'per4_allowlist_not_enforced:%',v_out->'dispatch';
  end if;

  ---------------------------------------------------------------------------
  -- D. Adapter state is revalidated at claim, before action consumption.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-revalidate','per4-regression-revalidate',v_state,
    '{"objective":"PER-4 adapter revalidate","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Revalidate provider adapter immediately before invocation.",
       "execution_mode":"server_executable","required_capability":"github.repository.read",
       "failure_policy":"stop","max_attempts":1,"timeout_seconds":60,
       "authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  perform public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-revalidate','github-read','per4-reg-revalidate:dispatch',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );

  update public.control_room_execution_provider_adapters_v1
  set status='disabled'
  where adapter_key='github.connector.read.v1';

  v_rejected := false;
  begin
    perform public.control_room_claim_project_graph_provider_dispatch_v1(
      'per4-regression-revalidate','per4-reg-revalidate:dispatch','per4-reg-revalidate:claim',60
    );
  exception when others then
    if position('provider_adapter_not_ready' in sqlerrm) > 0
       or position('provider_dispatch_route_changed' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;

  update public.control_room_execution_provider_adapters_v1
  set status='active'
  where adapter_key='github.connector.read.v1';

  if not v_rejected
     or (select actions_used from public.control_room_run_envelopes where run_key='per4-regression-revalidate') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per4-regression-revalidate' and node_key='github-read') <> 0 then
    raise exception 'per4_claim_revalidation_failed';
  end if;

  ---------------------------------------------------------------------------
  -- E. Provider result/evidence schemas are closed before node completion.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-output','per4-regression-output',v_state,
    '{"objective":"PER-4 output reject","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Reject unexpected provider output.","execution_mode":"server_executable",
       "required_capability":"github.repository.read","failure_policy":"stop",
       "max_attempts":1,"timeout_seconds":60,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":0,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-output','github-read','per4-reg-output:dispatch',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );
  v_invocation := v_out->'dispatch'->'provider_handoff'->>'provider_invocation_key';

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-output','per4-reg-output:dispatch','per4-reg-output:claim',60
  );
  v_token := (v_claim->'provider_claim'->>'lease_token')::uuid;

  v_rejected := false;
  begin
    perform public.control_room_finish_project_graph_provider_dispatch_v1(
      'per4-regression-output','per4-reg-output:dispatch','per4-reg-output:finish-bad',
      v_token,true,
      '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-29T12:00:00Z","unexpected":"no"}'::jsonb,
      jsonb_build_object(
        'provider','github',
        'adapter_key','github.connector.read.v1',
        'operation','get_repo',
        'provider_invocation_key',v_invocation,
        'credential_mode','connector_managed',
        'source_ref','github:repository:meterionops/meterion-hq',
        'returned_by','connected_github_provider'
      ),
      null
    );
  exception when others then
    if position('github_provider_result_extra_fields_rejected' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;

  if not v_rejected then
    raise exception 'per4_output_extra_field_not_rejected';
  end if;

  perform public.control_room_finish_project_graph_provider_dispatch_v1(
    'per4-regression-output','per4-reg-output:dispatch','per4-reg-output:finish-good',
    v_token,true,
    '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-29T12:00:00Z"}'::jsonb,
    jsonb_build_object(
      'provider','github',
      'adapter_key','github.connector.read.v1',
      'operation','get_repo',
      'provider_invocation_key',v_invocation,
      'credential_mode','connector_managed',
      'source_ref','github:repository:meterionops/meterion-hq',
      'returned_by','connected_github_provider'
    ),
    null
  );

  ---------------------------------------------------------------------------
  -- F. Provider failure uses the existing PER-2 retry budget/path.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-retry','per4-regression-retry',v_state,
    '{"objective":"PER-4 provider retry","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Retry provider failure through PER-2.","execution_mode":"server_executable",
       "required_capability":"github.repository.read","failure_policy":"retry",
       "max_attempts":2,"timeout_seconds":60,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":3,"max_retries":1,"max_spend_microusd":0}'::jsonb
  );

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-retry','github-read','per4-reg-retry:dispatch1',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );
  v_invocation := v_out->'dispatch'->'provider_handoff'->>'provider_invocation_key';

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-retry','per4-reg-retry:dispatch1','per4-reg-retry:claim1',60
  );
  v_token := (v_claim->'provider_claim'->>'lease_token')::uuid;

  perform public.control_room_finish_project_graph_provider_dispatch_v1(
    'per4-regression-retry','per4-reg-retry:dispatch1','per4-reg-retry:finish1',
    v_token,false,
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb,
    jsonb_build_object(
      'provider','github',
      'adapter_key','github.connector.read.v1',
      'operation','get_repo',
      'provider_invocation_key',v_invocation,
      'credential_mode','connector_managed',
      'source_ref','github:repository:meterionops/meterion-hq',
      'returned_by','connected_github_provider'
    ),
    'provider_unavailable'
  );

  perform public.control_room_retry_project_graph_node_v2(
    'per4-regression-retry','github-read','per4-reg-retry:retry',
    '{"provider_retry":"per2_canonical"}'::jsonb
  );

  if (select retries_used from public.control_room_run_envelopes where run_key='per4-regression-retry') <> 1 then
    raise exception 'per4_failure_retry_budget_wrong';
  end if;

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-retry','github-read','per4-reg-retry:dispatch2',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );
  v_invocation := v_out->'dispatch'->'provider_handoff'->>'provider_invocation_key';

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-retry','per4-reg-retry:dispatch2','per4-reg-retry:claim2',60
  );
  v_token := (v_claim->'provider_claim'->>'lease_token')::uuid;

  perform public.control_room_finish_project_graph_provider_dispatch_v1(
    'per4-regression-retry','per4-reg-retry:dispatch2','per4-reg-retry:finish2',
    v_token,true,
    '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-29T12:00:00Z"}'::jsonb,
    jsonb_build_object(
      'provider','github',
      'adapter_key','github.connector.read.v1',
      'operation','get_repo',
      'provider_invocation_key',v_invocation,
      'credential_mode','connector_managed',
      'source_ref','github:repository:meterionops/meterion-hq',
      'returned_by','connected_github_provider'
    ),
    null
  );

  if (select actions_used from public.control_room_run_envelopes where run_key='per4-regression-retry') <> 2
     or not exists (
       select 1 from public.control_room_project_graph_nodes_v1
       where graph_run_key='per4-regression-retry'
         and node_key='github-read'
         and status='completed'
         and attempt_count=2
     ) then
    raise exception 'per4_retry_recovery_wrong';
  end if;

  ---------------------------------------------------------------------------
  -- G. Lost provider worker is reconciled by the existing PER-2 wake/retry.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os','per4-regression-interrupt','per4-regression-interrupt',v_state,
    '{"objective":"PER-4 provider interruption","compiler_version":"per2"}'::jsonb,
    '[{"node_key":"github-read","node_type":"tool","action_kind":"github.repository.read",
       "purpose":"Recover interrupted provider execution.","execution_mode":"server_executable",
       "required_capability":"github.repository.read","failure_policy":"retry",
       "max_attempts":2,"timeout_seconds":60,"authority_class":"read_only"}]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":3,"max_retries":1,"max_spend_microusd":0}'::jsonb
  );

  perform public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-interrupt','github-read','per4-reg-int:dispatch1',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-interrupt','per4-reg-int:dispatch1','per4-reg-int:claim1',60
  );
  v_token := (v_claim->'provider_claim'->>'lease_token')::uuid;

  update public.control_room_project_graph_nodes_v1
  set lease_expires_at=clock_timestamp()-interval '1 second'
  where graph_run_key='per4-regression-interrupt'
    and node_key='github-read'
    and execution_token=v_token;

  perform public.control_room_wake_project_graph_v2(
    'per4-regression-interrupt','per4-reg-int:wake'
  );

  if not exists (
    select 1 from public.control_room_project_graph_dispatches_v1
    where graph_run_key='per4-regression-interrupt'
      and dispatch_key='per4-reg-int:dispatch1'
      and status='failed'
      and error_code='provider_execution_interrupted_requeued'
      and execution_token is null
  ) then
    raise exception 'per4_interrupted_dispatch_not_reconciled';
  end if;

  if (select retries_used from public.control_room_run_envelopes where run_key='per4-regression-interrupt') <> 1
     or not exists (
       select 1 from public.control_room_project_graph_nodes_v1
       where graph_run_key='per4-regression-interrupt'
         and node_key='github-read'
         and status='ready'
         and attempt_count=1
         and interruption_count=1
     ) then
    raise exception 'per4_interrupted_node_not_requeued';
  end if;

  v_out := public.control_room_dispatch_project_graph_node_v1(
    'per4-regression-interrupt','github-read','per4-reg-int:dispatch2',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );
  v_invocation := v_out->'dispatch'->'provider_handoff'->>'provider_invocation_key';

  v_claim := public.control_room_claim_project_graph_provider_dispatch_v1(
    'per4-regression-interrupt','per4-reg-int:dispatch2','per4-reg-int:claim2',60
  );
  v_token := (v_claim->'provider_claim'->>'lease_token')::uuid;

  perform public.control_room_finish_project_graph_provider_dispatch_v1(
    'per4-regression-interrupt','per4-reg-int:dispatch2','per4-reg-int:finish2',
    v_token,true,
    '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-29T12:00:00Z"}'::jsonb,
    jsonb_build_object(
      'provider','github',
      'adapter_key','github.connector.read.v1',
      'operation','get_repo',
      'provider_invocation_key',v_invocation,
      'credential_mode','connector_managed',
      'source_ref','github:repository:meterionops/meterion-hq',
      'returned_by','connected_github_provider'
    ),
    null
  );

  if (select actions_used from public.control_room_run_envelopes where run_key='per4-regression-interrupt') <> 2
     or not exists (
       select 1 from public.control_room_project_graph_nodes_v1
       where graph_run_key='per4-regression-interrupt'
         and node_key='github-read'
         and status='completed'
         and attempt_count=2
     ) then
    raise exception 'per4_interruption_recovery_wrong';
  end if;
end
$$;

rollback;

select jsonb_build_object(
  'runs',(select count(*) from public.control_room_project_graph_runs_v1 where run_key like 'per4-regression-%'),
  'dispatches',(select count(*) from public.control_room_project_graph_dispatches_v1 where graph_run_key like 'per4-regression-%'),
  'work_units',(select count(*) from public.control_room_project_work_units_v1 where work_unit_key like 'per4-regression-%')
) as residue;
