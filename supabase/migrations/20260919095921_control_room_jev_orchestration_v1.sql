create table if not exists public.control_room_run_envelopes (
  run_key text primary key,
  project_id uuid not null references public.control_room_projects(id) on delete cascade,
  status text not null default 'active' check (status in ('active','paused','blocked','completed')),
  max_actions integer check (max_actions is null or max_actions > 0),
  max_jev_calls integer check (max_jev_calls is null or max_jev_calls > 0),
  max_retries integer check (max_retries is null or max_retries >= 0),
  max_spend_microusd bigint check (max_spend_microusd is null or max_spend_microusd >= 0),
  actions_used integer not null default 0 check (actions_used >= 0),
  jev_calls_used integer not null default 0 check (jev_calls_used >= 0),
  retries_used integer not null default 0 check (retries_used >= 0),
  spend_microusd bigint not null default 0 check (spend_microusd >= 0),
  last_verified_checkpoint jsonb not null default '{}'::jsonb,
  action_space jsonb not null default '[]'::jsonb,
  context_filter jsonb not null default '{}'::jsonb,
  candidate_ranking jsonb not null default '{}'::jsonb,
  resume_from text,
  stop_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.control_room_run_envelopes enable row level security;
revoke all on public.control_room_run_envelopes from anon, authenticated;
grant select, insert, update on public.control_room_run_envelopes to service_role;

create or replace function public.control_room_checkpoint_run_v1(
  p_run_key text, p_project_id uuid, p_expected_status text default null, p_status text default null,
  p_actions_delta integer default 0, p_jev_calls_delta integer default 0, p_retries_delta integer default 0,
  p_spend_delta_microusd bigint default 0, p_last_verified_checkpoint jsonb default null,
  p_action_space jsonb default null, p_context_filter jsonb default null, p_candidate_ranking jsonb default null,
  p_resume_from text default null, p_stop_reason text default null
) returns public.control_room_run_envelopes
language plpgsql security definer set search_path = public as $$
declare v public.control_room_run_envelopes;
begin
  if p_actions_delta < 0 or p_jev_calls_delta < 0 or p_retries_delta < 0 or p_spend_delta_microusd < 0 then raise exception 'negative run deltas are not allowed'; end if;
  select * into v from public.control_room_run_envelopes where run_key=p_run_key and project_id=p_project_id for update;
  if not found then raise exception 'run envelope not found'; end if;
  if p_expected_status is not null and v.status<>p_expected_status then raise exception 'run status conflict'; end if;
  if v.max_actions is not null and v.actions_used+p_actions_delta>v.max_actions then raise exception 'run action budget exceeded'; end if;
  if v.max_jev_calls is not null and v.jev_calls_used+p_jev_calls_delta>v.max_jev_calls then raise exception 'run Jev budget exceeded'; end if;
  if v.max_retries is not null and v.retries_used+p_retries_delta>v.max_retries then raise exception 'run retry budget exceeded'; end if;
  if v.max_spend_microusd is not null and v.spend_microusd+p_spend_delta_microusd>v.max_spend_microusd then raise exception 'run spend budget exceeded'; end if;
  update public.control_room_run_envelopes set
    status=coalesce(p_status,status), actions_used=actions_used+p_actions_delta,
    jev_calls_used=jev_calls_used+p_jev_calls_delta, retries_used=retries_used+p_retries_delta,
    spend_microusd=spend_microusd+p_spend_delta_microusd,
    last_verified_checkpoint=coalesce(p_last_verified_checkpoint,last_verified_checkpoint),
    action_space=coalesce(p_action_space,action_space), context_filter=coalesce(p_context_filter,context_filter),
    candidate_ranking=coalesce(p_candidate_ranking,candidate_ranking), resume_from=coalesce(p_resume_from,resume_from),
    stop_reason=case when p_stop_reason is not null then p_stop_reason else stop_reason end, updated_at=now()
  where run_key=p_run_key returning * into v;
  return v;
end $$;

create or replace function public.control_room_get_run_resume_v1(p_run_key text) returns jsonb
language sql security definer set search_path=public as $$
 select jsonb_build_object(
  'run_key',r.run_key,'project_id',r.project_id,'status',r.status,
  'limits',jsonb_build_object('max_actions',r.max_actions,'max_jev_calls',r.max_jev_calls,'max_retries',r.max_retries,'max_spend_microusd',r.max_spend_microusd),
  'usage',jsonb_build_object('actions_used',r.actions_used,'jev_calls_used',r.jev_calls_used,'retries_used',r.retries_used,'spend_microusd',r.spend_microusd),
  'last_verified_checkpoint',r.last_verified_checkpoint,'action_space',r.action_space,'context_filter',r.context_filter,
  'candidate_ranking',r.candidate_ranking,'resume_from',r.resume_from,'stop_reason',r.stop_reason,'updated_at',r.updated_at)
 from public.control_room_run_envelopes r where r.run_key=p_run_key
$$;
revoke all on function public.control_room_checkpoint_run_v1(text,uuid,text,text,integer,integer,integer,bigint,jsonb,jsonb,jsonb,jsonb,text,text) from public,anon,authenticated;
grant execute on function public.control_room_checkpoint_run_v1(text,uuid,text,text,integer,integer,integer,bigint,jsonb,jsonb,jsonb,jsonb,text,text) to service_role;
revoke all on function public.control_room_get_run_resume_v1(text) from public,anon,authenticated;
grant execute on function public.control_room_get_run_resume_v1(text) to service_role;