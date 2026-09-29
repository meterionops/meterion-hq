-- Meterion Project Execution Runtime v1 — PER-5 worker-pickup rollback regression
-- Requires PER-5 worker pickup migration. Leaves no persistent test rows.

begin;

do $$
declare
  v_state integer;
  v_pickup jsonb;
  v_finish jsonb;
  v_token uuid;
  v_invocation text;
  v_rejected boolean := false;
begin
  v_state := (public.control_room_get_project_state_v3('ai-company-os')->>'state_version')::integer;

  ---------------------------------------------------------------------------
  -- A. Test isolation + empty eligible queue -> no claim.
  ---------------------------------------------------------------------------
  if exists (
    select 1
    from public.control_room_project_graph_dispatches_v1 d
    join public.control_room_project_graph_runs_v1 g on g.run_key=d.graph_run_key
    join public.control_room_project_graph_nodes_v1 n on n.graph_run_key=d.graph_run_key and n.id=d.node_id
    join public.control_room_projects p on p.id=d.project_id
    join public.control_room_run_envelopes r on r.run_key=d.graph_run_key
    where p.project_key='ai-company-os'
      and d.status='awaiting_provider'
      and d.provider_adapter_key='github.connector.read.v1'
      and g.status='active'
      and n.status='ready'
      and r.status='active'
  ) then
    raise exception 'per5_regression_requires_empty_provider_queue';
  end if;

  v_pickup := public.control_room_claim_next_project_graph_provider_dispatch_v1(
    'ai-company-os',
    'per5-regression-worker',
    array['github.connector.read.v1']::text[],
    120
  );

  if coalesce((v_pickup->>'claimed')::boolean,true) is not false
     or v_pickup->>'reason' <> 'no-awaiting-provider' then
    raise exception 'per5_empty_queue_not_reported:%',v_pickup;
  end if;

  ---------------------------------------------------------------------------
  -- B. Prepared provider handoff stays unclaimed for an unsupported adapter.
  ---------------------------------------------------------------------------
  perform public.control_room_create_project_work_graph_v2(
    'ai-company-os',
    'per5-regression-worker-pickup',
    'per5-regression-worker-pickup',
    v_state,
    '{"objective":"PER-5 worker pickup regression","compiler_version":"per2"}'::jsonb,
    '[{
      "node_key":"github-read",
      "node_type":"tool",
      "action_kind":"github.repository.read",
      "purpose":"Exercise automated provider worker pickup.",
      "execution_mode":"server_executable",
      "required_capability":"github.repository.read",
      "failure_policy":"retry",
      "max_attempts":2,
      "timeout_seconds":120,
      "authority_class":"read_only"
    }]'::jsonb,
    '[]'::jsonb,
    '{"max_actions":2,"max_retries":1,"max_spend_microusd":0}'::jsonb
  );

  perform public.control_room_dispatch_project_graph_node_v1(
    'per5-regression-worker-pickup',
    'github-read',
    'per5-regression-worker-pickup:dispatch',
    '{"repository_full_name":"meterionops/meterion-hq"}'::jsonb
  );

  v_pickup := public.control_room_claim_next_project_graph_provider_dispatch_v1(
    'ai-company-os',
    'per5-regression-worker',
    array['some.other-adapter']::text[],
    120
  );

  if coalesce((v_pickup->>'claimed')::boolean,true) is not false
     or (select actions_used from public.control_room_run_envelopes where run_key='per5-regression-worker-pickup') <> 0
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per5-regression-worker-pickup' and node_key='github-read') <> 0 then
    raise exception 'per5_adapter_filter_consumed_budget';
  end if;

  ---------------------------------------------------------------------------
  -- C. Supported adapter pickup claims exactly once through PER-2.
  ---------------------------------------------------------------------------
  v_pickup := public.control_room_claim_next_project_graph_provider_dispatch_v1(
    'ai-company-os',
    'per5-regression-worker',
    array['github.connector.read.v1']::text[],
    120
  );

  if coalesce((v_pickup->>'claimed')::boolean,false) is not true
     or v_pickup->'provider_claim'->>'status' <> 'executing'
     or v_pickup->'provider_claim'->>'provider_adapter_key' <> 'github.connector.read.v1'
     or v_pickup->'provider_claim'->>'provider_operation' <> 'get_repo'
     or v_pickup->'provider_claim'->>'credential_mode' <> 'connector_managed' then
    raise exception 'per5_supported_pickup_failed:%',v_pickup;
  end if;

  v_token := (v_pickup->'provider_claim'->>'lease_token')::uuid;
  v_invocation := v_pickup->'provider_claim'->>'provider_invocation_key';

  if (select actions_used from public.control_room_run_envelopes where run_key='per5-regression-worker-pickup') <> 1
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per5-regression-worker-pickup' and node_key='github-read') <> 1 then
    raise exception 'per5_pickup_budget_wrong';
  end if;

  if not exists (
    select 1
    from public.control_room_project_graph_dispatches_v1
    where graph_run_key='per5-regression-worker-pickup'
      and dispatch_key='per5-regression-worker-pickup:dispatch'
      and status='executing'
      and evidence->'worker_pickup'->>'worker_key'='per5-regression-worker'
      and evidence->'worker_pickup'->>'claim_key' is not null
  ) then
    raise exception 'per5_worker_pickup_evidence_missing';
  end if;

  ---------------------------------------------------------------------------
  -- D. A second poll cannot claim the executing dispatch or spend again.
  ---------------------------------------------------------------------------
  v_pickup := public.control_room_claim_next_project_graph_provider_dispatch_v1(
    'ai-company-os',
    'per5-regression-worker',
    array['github.connector.read.v1']::text[],
    120
  );

  if coalesce((v_pickup->>'claimed')::boolean,true) is not false
     or (select actions_used from public.control_room_run_envelopes where run_key='per5-regression-worker-pickup') <> 1
     or (select attempt_count from public.control_room_project_graph_nodes_v1
         where graph_run_key='per5-regression-worker-pickup' and node_key='github-read') <> 1 then
    raise exception 'per5_duplicate_poll_claimed_or_spent';
  end if;

  ---------------------------------------------------------------------------
  -- E. Existing PER-4 finish contract closes the claimed node.
  ---------------------------------------------------------------------------
  v_finish := public.control_room_finish_project_graph_provider_dispatch_v1(
    'per5-regression-worker-pickup',
    'per5-regression-worker-pickup:dispatch',
    'per5-regression-worker-pickup:finish',
    v_token,
    true,
    '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-29T13:40:00Z"}'::jsonb,
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

  if v_finish->'provider_finish'->>'success' <> 'true'
     or not exists (
       select 1 from public.control_room_project_graph_nodes_v1
       where graph_run_key='per5-regression-worker-pickup'
         and node_key='github-read'
         and status='completed'
         and attempt_count=1
     )
     or (select status from public.control_room_run_envelopes where run_key='per5-regression-worker-pickup') <> 'completed' then
    raise exception 'per5_finish_after_worker_pickup_failed';
  end if;

  ---------------------------------------------------------------------------
  -- F. Invalid worker contract fails closed.
  ---------------------------------------------------------------------------
  begin
    perform public.control_room_claim_next_project_graph_provider_dispatch_v1(
      'ai-company-os',
      'per5-regression-worker',
      array[]::text[],
      120
    );
  exception when others then
    if position('supported_adapter_keys_required' in sqlerrm) > 0 then
      v_rejected := true;
    else
      raise;
    end if;
  end;

  if not v_rejected then
    raise exception 'per5_empty_supported_adapter_set_not_rejected';
  end if;
end
$$;

rollback;

select jsonb_build_object(
  'runs',(select count(*) from public.control_room_project_graph_runs_v1 where run_key like 'per5-regression-%'),
  'dispatches',(select count(*) from public.control_room_project_graph_dispatches_v1 where graph_run_key like 'per5-regression-%'),
  'work_units',(select count(*) from public.control_room_project_work_units_v1 where work_unit_key like 'per5-regression-%')
) as residue;
