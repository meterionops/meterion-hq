begin;

-- Control Room Projects v2
-- Derived portfolio/read-model only. Canonical write model remains:
-- Project -> State -> Event -> Connection.

create or replace view public.control_room_projects_surface_v2
with (security_invoker = true)
as
select
  s.*,
  (s.portfolio_class <> 'UNCONFIRMED') as classification_verified,
  (s.lifecycle_status <> 'unconfirmed') as lifecycle_verified,
  case
    when s.portfolio_class = 'SYSTEM' then 'system'
    when s.lifecycle_status = 'active' and s.portfolio_class = 'UNCONFIRMED' then 'active_unclassified'
    when s.lifecycle_status = 'active' then 'active_portfolio'
    when s.lifecycle_status = 'unconfirmed' then 'unconfirmed_identity'
    else 'inactive'
  end as projects_section,
  case
    when s.lifecycle_status = 'active' and s.state_freshness in ('stale','missing') then true
    else false
  end as state_quality_exception,
  array_remove(array[
    case when s.portfolio_class = 'UNCONFIRMED' then 'classification_unconfirmed'::text end,
    case when s.lifecycle_status = 'unconfirmed' then 'lifecycle_unconfirmed'::text end,
    case when s.state_freshness = 'missing' then 'state_missing'::text end,
    case when s.state_freshness = 'stale' then 'state_stale'::text end
  ], null) as verification_flags,
  coalesce(c.connection_count, 0)::integer as connection_count,
  c.primary_connection_type,
  c.primary_connection_label,
  c.primary_connection_ref,
  c.primary_connection_url
from public.control_room_project_summary_v2 s
left join lateral (
  select
    count(*)::integer as connection_count,
    (array_agg(pc.connection_type order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_type,
    (array_agg(pc.label order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_label,
    (array_agg(pc.external_ref order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_ref,
    (array_agg(pc.url order by pc.is_primary desc, pc.created_at asc))[1] as primary_connection_url
  from public.control_room_project_connections pc
  where pc.project_id = s.id
) c on true;

create or replace view public.control_room_projects_overview_v2
with (security_invoker = true)
as
select
  count(*)::integer as total_registered,
  count(*) filter (where projects_section = 'active_portfolio')::integer as active_portfolio_count,
  count(*) filter (where projects_section = 'active_unclassified')::integer as active_unclassified_count,
  count(*) filter (where projects_section = 'unconfirmed_identity')::integer as unconfirmed_identity_count,
  count(*) filter (where projects_section = 'inactive')::integer as inactive_count,
  count(*) filter (where projects_section = 'system')::integer as system_count,
  count(*) filter (where state_quality_exception)::integer as active_state_quality_exception_count,
  count(*) filter (where state_freshness = 'missing')::integer as missing_state_count,
  count(*) filter (where founder_attention_required)::integer as owner_attention_count,
  coalesce(sum(connection_count), 0)::integer as connection_count
from public.control_room_projects_surface_v2;

create or replace function public.control_room_get_projects_surface_v2(
  p_projects_section text default null,
  p_portfolio_class text default null,
  p_state_freshness text default null
)
returns setof public.control_room_projects_surface_v2
language sql
security definer
set search_path = public
as $$
  select *
  from public.control_room_projects_surface_v2
  where (p_projects_section is null or projects_section = p_projects_section)
    and (p_portfolio_class is null or portfolio_class = p_portfolio_class)
    and (p_state_freshness is null or state_freshness = p_state_freshness)
  order by
    case projects_section
      when 'active_portfolio' then 0
      when 'active_unclassified' then 1
      when 'unconfirmed_identity' then 2
      when 'inactive' then 3
      when 'system' then 4
      else 5
    end,
    case portfolio_class
      when 'CORE' then 0
      when 'EXPERIMENT' then 1
      when 'AUTOPILOT' then 2
      when 'MAINTENANCE' then 3
      when 'VAULT' then 4
      when 'SYSTEM' then 5
      else 6
    end,
    name;
$$;

create or replace function public.control_room_get_projects_overview_v2()
returns jsonb
language sql
security definer
set search_path = public
as $$
  select to_jsonb(x)
  from public.control_room_projects_overview_v2 x;
$$;

revoke all on public.control_room_projects_surface_v2 from public, anon, authenticated;
revoke all on public.control_room_projects_overview_v2 from public, anon, authenticated;

revoke all on function public.control_room_get_projects_surface_v2(text, text, text) from public, anon, authenticated;
revoke all on function public.control_room_get_projects_overview_v2() from public, anon, authenticated;

grant execute on function public.control_room_get_projects_surface_v2(text, text, text) to service_role;
grant execute on function public.control_room_get_projects_overview_v2() to service_role;

comment on view public.control_room_projects_surface_v2 is
  'Projects v2 read model: verified portfolio status, unconfirmed identities, state quality and source connection summary without task-manager semantics.';
comment on view public.control_room_projects_overview_v2 is
  'Compact Projects v2 portfolio-quality counts for the Control Room header/system diagnostics.';

commit;
