begin;

-- Sync the live Control Room registry to the Owner-confirmed Project Registry v1.
-- These rows intentionally remain UNCONFIRMED / unconfirmed unless the Owner has
-- explicitly classified or activated them. Repository presence is not treated as
-- proof of active project status.

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
) values
  (
    'calendar-platform',
    'Calendar Platform',
    'platform',
    'Operate a shared calendar/date utility platform with locally adapted country frontends and reusable validated calendar logic.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    'meterionops/paivasta-selva',
    jsonb_build_array('Country frontends are not separate top-level Control Room projects by default')
  ),
  (
    'yritystiedot',
    'Yritystiedot',
    'data_asset',
    'Maintain reusable Finnish company-data infrastructure that can support multiple Meterion products without creating competing master-data sources.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    jsonb_build_array('Treat company master data as a shared asset, not duplicated per product')
  ),
  (
    'nordic-bottle-index',
    'Nordic Bottle Index',
    'product',
    'Build and maintain cross-country Nordic beverage product matching and price-comparison intelligence.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    'meterionops/nordic-bottle-index-v2',
    '[]'::jsonb
  ),
  (
    'namorada',
    'Namorada',
    'product',
    'Support charter administration workflows across customers, cruises, communications and billing.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    '[]'::jsonb
  ),
  (
    'tinku-latin-flavors',
    'Tinku Latin Flavors',
    'client_operation',
    'Maintain the client restaurant website and reservation presence.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    '[]'::jsonb
  ),
  (
    'house-of-flores',
    'House of Flores',
    'client_operation',
    'Maintain the client salon web presence, SEO and Timma conversion path.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    '[]'::jsonb
  ),
  (
    'volaire',
    'Volaire',
    'product',
    'Build practical European airport passenger information and discovery surfaces.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    'meterionops/volairport',
    '[]'::jsonb
  ),
  (
    'pelovio',
    'Pelovio',
    'product',
    'Build a country-manual and travel-guide product distinct from the airport-specific Volaire domain.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    jsonb_build_array('Keep distinct from Volaire / airport passenger information')
  ),
  (
    'avoinna',
    'Avoinna',
    'product',
    'Build a Finland-wide opening-hours discovery service.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    '[]'::jsonb
  ),
  (
    'digiapu247',
    'Digiapu247',
    'product',
    'Validate an autonomous Finnish AI phone-support service that resolves customer problems safely and can earn real revenue.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    'meterionops/digiapu247',
    jsonb_build_array('Never request passwords, PIN codes, banking credentials or full payment-card data')
  ),
  (
    'sprinkler-water-tank-site',
    'Sprinkler Water Tank — site delivery / compliance',
    'client_operation',
    'Preserve the site-delivery, compliance and closeout operating picture for the sprinkler water tank job.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    null,
    jsonb_build_array('Never merge this client delivery project with Sprinkler RFQ Platform')
  )
on conflict (project_key) do nothing;

-- Durable Owner decision: Pertti and CityOS are historical and must not be
-- silently reintroduced into the active Control Room portfolio.
update public.control_room_projects
set canonical_constraints = canonical_constraints || jsonb_build_array(
      'Pertti and CityOS are historical projects and must not be surfaced as current portfolio projects unless the Owner explicitly reactivates them.'
    ),
    updated_at = now()
where project_key = 'meterion-control-room'
  and not canonical_constraints @> jsonb_build_array(
    'Pertti and CityOS are historical projects and must not be surfaced as current portfolio projects unless the Owner explicitly reactivates them.'
  );

-- Known GitHub connections. Multiple repositories may belong to one project.
with connection_seed(project_key, connection_type, label, external_ref, url, is_primary) as (
  values
    ('calendar-platform','github','Kalenterissa.fi GitHub','meterionops/paivasta-selva','https://github.com/meterionops/paivasta-selva',true),
    ('calendar-platform','github','Kalenderklart GitHub','meterionops/kalenderklart','https://github.com/meterionops/kalenderklart',false),
    ('calendar-platform','github','Calendify / France GitHub','meterionops/calendify-your-world','https://github.com/meterionops/calendify-your-world',false),
    ('calendar-platform','github','Kalenderpunkt GitHub','meterionops/kalenderpunkt','https://github.com/meterionops/kalenderpunkt',false),
    ('nordic-bottle-index','github','Nordic Bottle Index v2 GitHub','meterionops/nordic-bottle-index-v2','https://github.com/meterionops/nordic-bottle-index-v2',true),
    ('nordic-bottle-index','github','Nordic Bottle Index legacy GitHub','meterionops/nordic-bottle-index','https://github.com/meterionops/nordic-bottle-index',false),
    ('nordic-bottle-index','github','Nordic Bottle Index source GitHub','meterionops/nordic-bottle-index-source','https://github.com/meterionops/nordic-bottle-index-source',false),
    ('nordic-bottle-index','github','Nordic Bottle Compass GitHub','meterionops/nordic-bottle-compass','https://github.com/meterionops/nordic-bottle-compass',false),
    ('volaire','github','Volairport GitHub','meterionops/volairport','https://github.com/meterionops/volairport',true),
    ('digiapu247','github','Digiapu247 GitHub','meterionops/digiapu247','https://github.com/meterionops/digiapu247',true)
)
insert into public.control_room_project_connections (
  project_id,
  connection_type,
  label,
  external_ref,
  url,
  is_primary
)
select
  p.id,
  s.connection_type,
  s.label,
  s.external_ref,
  s.url,
  s.is_primary
from connection_seed s
join public.control_room_projects p on p.project_key = s.project_key
on conflict (project_id, connection_type, external_ref) do update set
  label = excluded.label,
  url = excluded.url,
  is_primary = excluded.is_primary,
  updated_at = now();

commit;
