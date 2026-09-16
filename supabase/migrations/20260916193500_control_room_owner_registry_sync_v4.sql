begin;

-- Owner registry sync v4
-- Authority: docs/control-room/OWNER_RECONCILIATION_V2.md
-- Owner confirmed 2026-09-16.

-- Tinku Latin Flavors is explicitly removed from Control Room entirely.
-- Child state/event/connection rows cascade with the project row.
delete from public.control_room_projects
where project_key = 'tinku-latin-flavors';

-- Fire Sprinkler Hub is a distinct top-level product from Sprinkler RFQ Platform.
insert into public.control_room_projects (
  project_key,
  name,
  kind,
  goal,
  portfolio_class,
  lifecycle_status,
  state_authority,
  primary_workspace,
  canonical_constraints
) values (
  'fire-sprinkler-hub',
  'Fire Sprinkler Hub',
  'product',
  'Build a manufacturer-independent fire-sprinkler search, selection, comparison and verification platform for fire-protection professionals.',
  'UNCONFIRMED',
  'active',
  'control_room',
  'meterionops/fire-sprinkler-hub',
  jsonb_build_array(
    'Keep Fire Sprinkler Hub separate from Sprinkler RFQ Platform',
    'Technical ranking must remain manufacturer-neutral',
    'Unknown technical data must not be treated as false',
    'Coverage is a first-class product attribute'
  )
)
on conflict (project_key) do update set
  name = excluded.name,
  kind = excluded.kind,
  goal = excluded.goal,
  lifecycle_status = excluded.lifecycle_status,
  state_authority = excluded.state_authority,
  primary_workspace = excluded.primary_workspace,
  canonical_constraints = excluded.canonical_constraints,
  updated_at = now();

-- Microapps Factory is intentionally only an idea-stage registry entry.
insert into public.control_room_projects (
  project_key,
  name,
  kind,
  goal,
  portfolio_class,
  lifecycle_status,
  state_authority,
  primary_workspace,
  canonical_constraints
) values (
  'microapps-factory',
  'Microapps Factory',
  'candidate',
  'Design a factory for creating and operating small micro-app products in connection with AI Company OS.',
  'UNCONFIRMED',
  'unconfirmed',
  'control_room',
  null,
  jsonb_build_array(
    'Idea stage only; do not treat as an active build until explicitly activated',
    'Planned to connect with AI Company OS at a later stage',
    'Do not represent Microapps Factory as an existing AI Company or implemented AI Company OS subsystem before it exists'
  )
)
on conflict (project_key) do update set
  name = excluded.name,
  kind = excluded.kind,
  goal = excluded.goal,
  lifecycle_status = excluded.lifecycle_status,
  state_authority = excluded.state_authority,
  primary_workspace = excluded.primary_workspace,
  canonical_constraints = excluded.canonical_constraints,
  updated_at = now();

-- Correct the earlier source-identity conflation. These belong to Fire Sprinkler Hub,
-- not Sprinkler RFQ Platform. TankB2B remains the RFQ Platform primary operating source.
delete from public.control_room_project_connections c
using public.control_room_projects p
where c.project_id = p.id
  and p.project_key = 'sprinkler-rfq-platform'
  and (
    (c.connection_type = 'github' and c.external_ref = 'meterionops/fire-sprinkler-hub')
    or (c.connection_type = 'lovable' and c.external_ref = '861026d9-38b8-4d3e-bb05-250fc4ab1080')
  );

with connection_seed(project_key, connection_type, label, external_ref, url, is_primary, metadata) as (
  values
    ('fire-sprinkler-hub','supabase','Sprinkler Hub Supabase','imzdpkekrdzjiqqpqbmk',null,true,'{}'::jsonb),
    ('fire-sprinkler-hub','github','Fire Sprinkler Hub GitHub','meterionops/fire-sprinkler-hub','https://github.com/meterionops/fire-sprinkler-hub',false,'{}'::jsonb),
    ('fire-sprinkler-hub','lovable','Fire Sprinkler Hub Lovable','861026d9-38b8-4d3e-bb05-250fc4ab1080','https://lovable.dev/projects/861026d9-38b8-4d3e-bb05-250fc4ab1080',false,'{}'::jsonb),
    ('microapps-factory','ai_company_os','Planned AI Company OS integration','ai-company-os',null,true,jsonb_build_object('relation','planned_integration','status','idea_stage'))
)
insert into public.control_room_project_connections (
  project_id,
  connection_type,
  label,
  external_ref,
  url,
  is_primary,
  metadata
)
select
  p.id,
  s.connection_type,
  s.label,
  s.external_ref,
  s.url,
  s.is_primary,
  s.metadata
from connection_seed s
join public.control_room_projects p on p.project_key = s.project_key
on conflict (project_id, connection_type, external_ref) do update set
  label = excluded.label,
  url = excluded.url,
  is_primary = excluded.is_primary,
  metadata = excluded.metadata,
  updated_at = now();

commit;
