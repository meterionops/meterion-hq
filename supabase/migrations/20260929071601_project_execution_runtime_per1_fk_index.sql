create index if not exists control_room_project_graph_runs_v1_work_unit_project_idx
  on public.control_room_project_graph_runs_v1(work_unit_id, project_id);
