begin;

-- Control Room State Reconciliation v1
-- Derived operational refresh queue only. It never mutates Owner-controlled
-- Project identity/classification/lifecycle fields.

create or replace view public.control_room_state_reconciliation_v1
with (security_invoker = true)
as
select
  p.project_key,
  p.name,
  p.portfolio_class,
  p.lifecycle_status,
  p.projects_section,
  p.state_authority,
  p.state_version,
  p.state_freshness,
  p.state_age_hours,
  p.verified_at,
  p.confidence,
  p.source_type as current_state_source_type,
  p.source_ref as current_state_source_ref,
  p.primary_connection_type,
  p.primary_connection_label,
  p.primary_connection_ref,
  p.primary_connection_url,
  case
    when p.portfolio_class in ('CORE','SYSTEM') then 24
    when p.portfolio_class = 'EXPERIMENT' then 48
    when p.portfolio_class = 'AUTOPILOT' then 72
    when p.portfolio_class = 'MAINTENANCE' then 168
    when p.portfolio_class = 'VAULT' then null
    when p.lifecycle_status = 'active' then 48
    else null
  end as target_refresh_hours,
  case
    when p.state_authority = 'manual' then 'manual_evidence'
    when p.primary_connection_type in ('supabase','github','ai_company_os') then 'direct_source'
    when p.primary_connection_ref is not null then 'source_index'
    else 'manual_evidence'
  end as refresh_mode,
  case
    when p.lifecycle_status <> 'active' then false
    when p.portfolio_class = 'VAULT' then false
    when p.state_missing then true
    when p.verified_at is null then true
    when p.portfolio_class in ('CORE','SYSTEM') then p.verified_at < now() - interval '24 hours'
    when p.portfolio_class = 'EXPERIMENT' then p.verified_at < now() - interval '48 hours'
    when p.portfolio_class = 'AUTOPILOT' then p.verified_at < now() - interval '72 hours'
    when p.portfolio_class = 'MAINTENANCE' then p.verified_at < now() - interval '168 hours'
    when p.lifecycle_status = 'active' then p.verified_at < now() - interval '48 hours'
    else false
  end as refresh_due,
  case
    when p.lifecycle_status <> 'active' then false
    when p.state_authority = 'manual' then false
    when p.primary_connection_ref is null then false
    when p.primary_connection_type in ('supabase','github','ai_company_os') then true
    else false
  end as safe_to_auto_refresh,
  case
    when p.lifecycle_status <> 'active' then 'none'
    when p.state_missing then 'high'
    when p.state_freshness = 'stale' and p.portfolio_class in ('CORE','SYSTEM') then 'high'
    when p.state_freshness in ('stale','aging') then 'normal'
    when p.portfolio_class = 'UNCONFIRMED' then 'low'
    else 'none'
  end as reconciliation_priority,
  case
    when p.lifecycle_status <> 'active' then 'inactive_project'
    when p.portfolio_class = 'VAULT' then 'vault_no_routine_refresh'
    when p.state_missing then 'operational_state_missing'
    when p.state_freshness = 'stale' then 'operational_state_stale'
    when p.state_freshness = 'aging' then 'operational_state_aging'
    when p.portfolio_class = 'UNCONFIRMED' then 'active_project_classification_unconfirmed_but_operational_state_can_refresh'
    else 'current'
  end as reconciliation_reason
from public.control_room_projects_surface_v2 p;

create or replace function public.control_room_get_state_reconciliation_v1(
  p_due_only boolean default true,
  p_portfolio_class text default null
)
returns setof public.control_room_state_reconciliation_v1
language sql
security definer
set search_path = public
as $$
  select *
  from public.control_room_state_reconciliation_v1
  where (not p_due_only or refresh_due)
    and (p_portfolio_class is null or portfolio_class = p_portfolio_class)
  order by
    case reconciliation_priority
      when 'high' then 0
      when 'normal' then 1
      when 'low' then 2
      else 3
    end,
    case portfolio_class
      when 'CORE' then 0
      when 'EXPERIMENT' then 1
      when 'AUTOPILOT' then 2
      when 'MAINTENANCE' then 3
      when 'SYSTEM' then 4
      when 'VAULT' then 5
      else 6
    end,
    state_age_hours desc nulls first,
    name;
$$;

revoke all on public.control_room_state_reconciliation_v1 from public, anon, authenticated;
revoke all on function public.control_room_get_state_reconciliation_v1(boolean, text) from public, anon, authenticated;
grant execute on function public.control_room_get_state_reconciliation_v1(boolean, text) to service_role;

comment on view public.control_room_state_reconciliation_v1 is
  'Bounded source-backed operational state refresh queue. Never authorizes AI to change Owner-controlled project identity, portfolio class, lifecycle or canonical constraints.';

commit;
