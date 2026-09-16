begin;

-- Owner portfolio sync v3
--
-- Source of authority:
--   docs/control-room/OWNER_RECONCILIATION_PROPOSAL_V1.md
--   Status: OWNER CONFIRMED / 2026-09-12
--
-- This migration does not invent portfolio classifications. It reconciles the
-- live registry with the already-confirmed Owner baseline that was not carried
-- through by registry_sync_v2.
--
-- Lifecycle interpretation:
-- - EXPERIMENT / AUTOPILOT / MAINTENANCE entries in the confirmed current
--   visible portfolio baseline are active unless the Owner explicitly placed
--   them in the "VAULT / paused" group.
-- - Volaire, Pelovio, Avoinna and Digiapu247 are therefore paused.
-- - Sprinkler Water Tank receives its confirmed MAINTENANCE class, but its
--   lifecycle is deliberately left unchanged. The Owner baseline says
--   "site delivery after closeout" while current source evidence does not yet
--   prove closeout, so Control Room must not silently mark it completed.

with owner_baseline(project_key, portfolio_class, lifecycle_status) as (
  values
    ('folio', 'EXPERIMENT', 'active'),
    ('calendar-platform', 'AUTOPILOT', 'active'),
    ('yritystiedot', 'AUTOPILOT', 'active'),
    ('nordic-bottle-index', 'AUTOPILOT', 'active'),
    ('namorada', 'MAINTENANCE', 'active'),
    ('tinku-latin-flavors', 'MAINTENANCE', 'active'),
    ('house-of-flores', 'MAINTENANCE', 'active'),
    ('volaire', 'VAULT', 'paused'),
    ('pelovio', 'VAULT', 'paused'),
    ('avoinna', 'VAULT', 'paused'),
    ('digiapu247', 'VAULT', 'paused')
)
update public.control_room_projects p
set portfolio_class = b.portfolio_class,
    lifecycle_status = b.lifecycle_status,
    updated_at = now()
from owner_baseline b
where p.project_key = b.project_key
  and (p.portfolio_class, p.lifecycle_status)
      is distinct from (b.portfolio_class, b.lifecycle_status);

update public.control_room_projects
set portfolio_class = 'MAINTENANCE',
    canonical_constraints = case
      when canonical_constraints @> jsonb_build_array(
        'Owner-confirmed portfolio class is MAINTENANCE; lifecycle remains unconfirmed until current site-delivery/closeout evidence is verified.'
      ) then canonical_constraints
      else canonical_constraints || jsonb_build_array(
        'Owner-confirmed portfolio class is MAINTENANCE; lifecycle remains unconfirmed until current site-delivery/closeout evidence is verified.'
      )
    end,
    updated_at = now()
where project_key = 'sprinkler-water-tank-site'
  and (
    portfolio_class is distinct from 'MAINTENANCE'
    or not canonical_constraints @> jsonb_build_array(
      'Owner-confirmed portfolio class is MAINTENANCE; lifecycle remains unconfirmed until current site-delivery/closeout evidence is verified.'
    )
  );

commit;
