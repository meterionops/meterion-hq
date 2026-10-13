-- No new task ledger: the existing PER work unit and six graph nodes are canonical.
create or replace function public.control_room_save_incubator_team_artifact_v1(p_run_key text,p_artifact jsonb)
returns jsonb language plpgsql security invoker set search_path=public,pg_temp as $$
declare w public.control_room_project_work_units_v1%rowtype; c public.control_room_project_connections%rowtype; b jsonb; k text;
begin
 select u.* into w from public.control_room_project_work_units_v1 u join public.control_room_project_graph_runs_v1 g on g.work_unit_id=u.id where g.run_key=p_run_key for update of u;
 if not found or w.project_id not in ('a856b823-6520-40e2-abca-067dcb93795e'::uuid,'cc187b93-a3fa-485c-a8fb-22e36bd3b7cc'::uuid) or w.scope_contract->>'action'<>'save_internal_preparation' then raise exception 'team_scope_invalid'; end if;
 if not exists(select 1 from public.control_room_project_graph_nodes_v1 where graph_run_key=p_run_key and node_key='execute' and status='running') or (select count(*) from public.control_room_project_graph_nodes_v1 where graph_run_key=p_run_key and node_key in ('observe','propose','analyse','decide') and status='completed')<>4 then raise exception 'team_decision_missing'; end if;
 select * into c from public.control_room_project_connections where id=(w.scope_contract->>'connection_id')::uuid and project_id=w.project_id for share;
 if not found or c.metadata->'office_incubator'->>'parent_project_id'<>w.project_id::text then raise exception 'team_connection_invalid'; end if;
 k:=w.scope_contract->>'target_key';
 if k like 'miniapp-%' then
  select brand->'products'->(substring(k from 9)::integer+1)->'build_brief' into b from jsonb_array_elements(c.metadata->'office_incubator'->'brands') brand where brand->>'key'='yritystentiedot';
 else
  select brand->'build_brief' into b from jsonb_array_elements(c.metadata->'office_incubator'->'brands') brand where brand->>'key'=k;
 end if;
 if b is distinct from w.scope_contract->'source_brief' then raise exception 'team_source_changed'; end if;
 if jsonb_typeof(p_artifact)<>'object' or p_artifact->>'target_key' is distinct from k or p_artifact->>'source_hash' is distinct from w.scope_contract->>'source_hash' or p_artifact->>'action'<>'save_internal_preparation' or p_artifact->>'artifact_status'<>'proposed' or p_artifact->'analysis'->>'approve'<>'true' or jsonb_array_length(p_artifact->'provider_runs')<>2 then raise exception 'team_artifact_invalid'; end if;
 update public.control_room_project_work_units_v1 set metadata=jsonb_set(metadata,'{office_team,artifact}',p_artifact,true),updated_at=now() where id=w.id;
 return jsonb_build_object('artifact',p_artifact,'work_unit_id',w.id);
end $$;
revoke all on function public.control_room_save_incubator_team_artifact_v1(text,jsonb) from public,anon,authenticated;
grant execute on function public.control_room_save_incubator_team_artifact_v1(text,jsonb) to service_role;
