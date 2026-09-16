begin;

-- Owner registry sync v5
-- Authority: docs/control-room/OWNER_RECONCILIATION_V3.md
-- Owner confirmed 2026-09-16.

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
    'foreign-contractor-finland',
    'Foreign Contractor Finland',
    'candidate',
    'Develop the Foreign Contractor Finland concept from the existing prototype when explicitly activated.',
    'UNCONFIRMED',
    'unconfirmed',
    'control_room',
    'ChatGPT Sites prototype',
    jsonb_build_array(
      'Idea stage only until explicitly activated',
      'An existing ChatGPT Sites prototype does not by itself make the project an active production product'
    )
  ),
  (
    'korvauskirje',
    'Korvauskirje',
    'product',
    'Help Finnish air passengers prepare ready-to-send flight-compensation claim letters through a guided paid self-service flow.',
    'UNCONFIRMED',
    'active',
    'control_room',
    'Lovable + Supabase',
    jsonb_build_array(
      'Published product; portfolio class remains Owner-unconfirmed'
    )
  ),
  (
    'lomakone',
    'Lomakone',
    'product',
    'Help users discover and plan travel destinations through a published travel-planning product with search, content and affiliate monetization.',
    'UNCONFIRMED',
    'active',
    'control_room',
    'meterionops/Lomakone + Lovable',
    jsonb_build_array(
      'Published product; portfolio class remains Owner-unconfirmed'
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

with connection_seed(project_key, connection_type, label, external_ref, url, is_primary, metadata) as (
  values
    (
      'foreign-contractor-finland',
      'other',
      'ChatGPT Sites prototype',
      'foreign-contractor-finland-sites-prototype',
      null,
      true,
      jsonb_build_object('platform','chatgpt_sites','stage','prototype','url_verified',false)
    ),
    (
      'korvauskirje',
      'supabase',
      'Korvauskirje Supabase',
      'tylxmwmqfrbfthrsnpwy',
      null,
      true,
      '{}'::jsonb
    ),
    (
      'korvauskirje',
      'lovable',
      'Korvauskirje Lovable',
      '8234be17-972b-47db-a2a3-a0f686c6cee5',
      'https://lovable.dev/projects/8234be17-972b-47db-a2a3-a0f686c6cee5',
      false,
      jsonb_build_object('published',true)
    ),
    (
      'korvauskirje',
      'production',
      'Korvauskirje.fi',
      'korvauskirje.fi',
      'https://korvauskirje.fi',
      false,
      '{}'::jsonb
    ),
    (
      'lomakone',
      'github',
      'Lomakone GitHub',
      'meterionops/Lomakone',
      'https://github.com/meterionops/Lomakone',
      true,
      '{}'::jsonb
    ),
    (
      'lomakone',
      'lovable',
      'Lomakone Lovable',
      '7e6a2022-a993-40d8-b5de-b8507f6346e8',
      'https://lovable.dev/projects/7e6a2022-a993-40d8-b5de-b8507f6346e8',
      false,
      jsonb_build_object('published',true)
    ),
    (
      'lomakone',
      'production',
      'Lomakone.com',
      'lomakone.com',
      'https://lomakone.com',
      false,
      '{}'::jsonb
    )
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
