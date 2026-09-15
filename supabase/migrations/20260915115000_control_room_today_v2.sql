begin;

-- Control Room read model v2
-- Adds explicit state freshness and latest material-event context without
-- changing the canonical Project -> State -> Event -> Connection write model.

create or replace view public.control_room_project_summary_v2
with (security_invoker = true)
as
select
  s.*,
  case
    when s.state_missing or s.verified_at is null then 'missing'
    when s.verified_at >= now() - interval '24 hours' then 'fresh'
    when s.verified_at >= now() - interval '72 hours' then 'aging'
    else 'stale'
  end as state_freshness,
  case
    when s.verified_at is null then null
    else round((extract(epoch from (now() - s.verified_at)) / 3600.0)::numeric, 1)
  end as state_age_hours,
  e.event_type as latest_event_type,
  e.summary as latest_event_summary,
  e.importance as latest_event_importance,
  e.occurred_at as latest_event_at,
  e.source_type as latest_event_source_type,
  e.source_ref as latest_event_source_ref,
  coalesce(e.occurred_at >= now() - interval '72 hours', false) as recent_material_change
from public.control_room_project_summary_v1 s
left join lateral (
  select
    pe.event_type,
    pe.summary,
    pe.importance,
    pe.occurred_at,
    pe.source_type,
    pe.source_ref
  from public.control_room_project_events pe
  where pe.project_id = s.id
  order by pe.occurred_at desc, pe.created_at desc
  limit 1
) e on true;

create or replace view public.control_room_today_v2
with (security_invoker = true)
as
select
  s.*,
  case
    when s.founder_attention_required then 'needs_you'
    when s.autonomy_state = 'working' then 'working_now'
    else 'changed_materially'
  end as today_section,
  case
    when s.founder_attention_required then coalesce(s.founder_attention_reason, s.blocker_summary, s.next_best_action)
    when s.autonomy_state = 'working' then coalesce(s.autonomy_reason, s.current_focus)
    else s.latest_event_summary
  end as today_reason
from public.control_room_project_summary_v2 s
where s.lifecycle_status = 'active'
  and (
    s.founder_attention_required = true
    or s.autonomy_state = 'working'
    or s.recent_material_change = true
  )
order by
  case
    when s.founder_attention_required then 0
    when s.autonomy_state = 'working' then 1
    else 2
  end,
  case s.portfolio_class
    when 'CORE' then 0
    when 'EXPERIMENT' then 1
    when 'AUTOPILOT' then 2
    when 'MAINTENANCE' then 3
    when 'SYSTEM' then 4
    when 'VAULT' then 5
    else 6
  end,
  coalesce(s.latest_event_at, s.verified_at) desc nulls last,
  s.name;

create or replace function public.control_room_get_project_state_v2(p_project_key text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select to_jsonb(x)
  from public.control_room_project_summary_v2 x
  where x.project_key = p_project_key;
$$;

create or replace function public.control_room_list_projects_v2(
  p_portfolio_class text default null,
  p_lifecycle_status text default null
)
returns setof public.control_room_project_summary_v2
language sql
security definer
set search_path = public
as $$
  select *
  from public.control_room_project_summary_v2
  where (p_portfolio_class is null or portfolio_class = p_portfolio_class)
    and (p_lifecycle_status is null or lifecycle_status = p_lifecycle_status)
  order by
    case portfolio_class
      when 'CORE' then 0
      when 'EXPERIMENT' then 1
      when 'AUTOPILOT' then 2
      when 'MAINTENANCE' then 3
      when 'SYSTEM' then 4
      when 'VAULT' then 5
      else 6
    end,
    name;
$$;

create or replace function public.control_room_get_today_v2()
returns setof public.control_room_today_v2
language sql
security definer
set search_path = public
as $$
  select * from public.control_room_today_v2;
$$;

revoke all on public.control_room_project_summary_v2 from public, anon, authenticated;
revoke all on public.control_room_today_v2 from public, anon, authenticated;

revoke all on function public.control_room_get_project_state_v2(text) from public, anon, authenticated;
revoke all on function public.control_room_list_projects_v2(text, text) from public, anon, authenticated;
revoke all on function public.control_room_get_today_v2() from public, anon, authenticated;

grant execute on function public.control_room_get_project_state_v2(text) to service_role;
grant execute on function public.control_room_list_projects_v2(text, text) to service_role;
grant execute on function public.control_room_get_today_v2() to service_role;

comment on view public.control_room_project_summary_v2 is
  'Control Room project summary with freshness and latest material-event context.';
comment on view public.control_room_today_v2 is
  'Sparse Today surface: only founder attention, work in progress, or recent material change.';

commit;
