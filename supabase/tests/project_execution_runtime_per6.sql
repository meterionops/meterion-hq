-- PER-6 rollback regression: bounded readiness, duplicate ticks, shared claims and dependencies.
begin;
do $$
declare v_state integer; v_result jsonb; v_d record; v_claim jsonb; v_token uuid; v_rejected boolean:=false;
begin
 v_state:=(public.control_room_get_project_state_v3('ai-company-os')->>'state_version')::integer;
 perform public.control_room_create_project_work_graph_v2('ai-company-os','per6-regression','per6-regression',v_state,
 '{"objective":"PER-6 isolated regression","scope_contract":{"per6":{"max_parallel_nodes":2}}}'::jsonb,
 '[{"node_key":"read-a","node_type":"tool","action_kind":"github.repository.read","required_capability":"github.repository.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{"dispatch_input":{"repository_full_name":"meterionops/meterion-hq"}}},{"node_key":"read-b","node_type":"tool","action_kind":"github.repository.read","required_capability":"github.repository.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{"dispatch_input":{"repository_full_name":"meterionops/meterion-hq"}}},{"node_key":"read-c","node_type":"tool","action_kind":"github.repository.read","required_capability":"github.repository.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{"dispatch_input":{"repository_full_name":"meterionops/meterion-hq"}}},{"node_key":"join-state","node_type":"tool","action_kind":"control_room.project_state.read","required_capability":"control_room.project_state.read","execution_mode":"server_executable","authority_class":"read_only","failure_policy":"retry","max_attempts":2,"timeout_seconds":600,"input_contract":{}}]'::jsonb,'[{"from":"read-a","to":"join-state"},{"from":"read-b","to":"join-state"},{"from":"read-c","to":"join-state"}]'::jsonb,'{"max_actions":8,"max_retries":2,"max_spend_microusd":0}'::jsonb);
 v_result:=public.control_room_schedule_project_graph_ready_v1('per6-regression');
 if (v_result->>'scheduled')::integer<>2 then raise exception 'expected_two_handoffs:%',v_result; end if;
 perform public.control_room_schedule_project_graph_ready_v1('per6-regression');
 if (select count(*) from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-regression')<>2 then raise exception 'duplicate_tick'; end if;
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-regression')<>0 then raise exception 'prepare_spent_action'; end if;
 if (select status from public.control_room_project_graph_nodes_v1 where graph_run_key='per6-regression' and node_key='join-state')<>'waiting_dependency' then raise exception 'dependency_leaked'; end if;

 for v_d in select d.dispatch_key from public.control_room_project_graph_dispatches_v1 d where graph_run_key='per6-regression' order by d.dispatch_key loop
  perform public.control_room_claim_project_graph_provider_dispatch_v1('per6-regression',v_d.dispatch_key,'claim:'||v_d.dispatch_key,600);
 end loop;
 if (select count(*) from public.control_room_project_graph_nodes_v1 where graph_run_key='per6-regression' and status='running')<>2 then raise exception 'parallel_claim_missing'; end if;
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-regression')<>2 then raise exception 'parallel_accounting'; end if;

 -- Direct provider preparation cannot bypass the shared claim limit.
 perform public.control_room_dispatch_project_graph_node_v1('per6-regression','read-c','direct-third','{"repository_full_name":"meterionops/meterion-hq"}'::jsonb);
 begin
  perform public.control_room_claim_project_graph_provider_dispatch_v1('per6-regression','direct-third','direct-third-claim',600);
 exception when others then
  if position('per6_parallel_limit_reached' in sqlerrm)>0 then v_rejected:=true; else raise; end if;
 end;
 if not v_rejected then raise exception 'third_claim_bypassed_limit'; end if;
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-regression')<>2 then raise exception 'rejection_spent_action'; end if;
 
 -- Finish one, then the third may occupy its released slot.
 select * into v_d from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-regression' and status='executing' order by dispatch_key limit 1;
 perform public.control_room_finish_project_graph_provider_dispatch_v1('per6-regression',v_d.dispatch_key,'finish:'||v_d.dispatch_key,v_d.execution_token,true,
 '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-30T14:00:00Z"}'::jsonb,
 jsonb_build_object('provider','github','adapter_key','github.connector.read.v1','operation','get_repo','credential_mode','connector_managed','provider_invocation_key',v_d.provider_invocation_key,'source_ref','github:repository:meterionops/meterion-hq','returned_by','connected_github_provider'),null);
 perform public.control_room_claim_project_graph_provider_dispatch_v1('per6-regression','direct-third','direct-third-claim',600);
 for v_d in select * from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-regression' and status='executing' loop
  perform public.control_room_finish_project_graph_provider_dispatch_v1('per6-regression',v_d.dispatch_key,'finish:'||v_d.dispatch_key,v_d.execution_token,true,
  '{"repository_full_name":"meterionops/meterion-hq","default_branch":"main","provider_observed_at":"2026-09-30T14:00:00Z"}'::jsonb,
  jsonb_build_object('provider','github','adapter_key','github.connector.read.v1','operation','get_repo','credential_mode','connector_managed','provider_invocation_key',v_d.provider_invocation_key,'source_ref','github:repository:meterionops/meterion-hq','returned_by','connected_github_provider'),null);
 end loop;
 perform public.control_room_schedule_project_graph_ready_v1('per6-regression');
 if (select status from public.control_room_project_graph_runs_v1 where run_key='per6-regression')<>'completed' then raise exception 'join_not_completed'; end if;
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-regression')<>4 then raise exception 'final_action_count'; end if;
 perform public.control_room_schedule_project_graph_ready_v1('per6-regression');
 if (select actions_used from public.control_room_run_envelopes where run_key='per6-regression')<>4 then raise exception 'terminal_replay_spent'; end if;
 if has_function_privilege('anon','public.control_room_schedule_project_graph_ready_v1(text)','EXECUTE')
 or has_function_privilege('authenticated','public.control_room_schedule_project_graph_ready_v1(text)','EXECUTE')
 then raise exception 'public_scheduler_access'; end if;
end $$;
rollback;
select jsonb_build_object(
 'runs',(select count(*) from public.control_room_project_graph_runs_v1 where run_key='per6-regression'),
 'dispatches',(select count(*) from public.control_room_project_graph_dispatches_v1 where graph_run_key='per6-regression'),
 'work_units',(select count(*) from public.control_room_project_work_units_v1 where work_unit_key='per6-regression')) as residue;
