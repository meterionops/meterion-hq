begin;

-- Source connection sync v3
--
-- Add source systems that were directly verified during the 2026-09-16 state
-- reconciliation. For data-heavy projects, Supabase is the primary operating
-- truth source; GitHub/Lovable remain secondary implementation/front-end links.

-- Demote earlier GitHub primaries where a directly verified runtime/data source
-- now exists. Do not remove the GitHub connection itself.
update public.control_room_project_connections c
set is_primary = false,
    updated_at = now()
from public.control_room_projects p
where c.project_id = p.id
  and p.project_key in ('calendar-platform','nordic-bottle-index','digiapu247')
  and c.is_primary;

with connection_seed(project_key, connection_type, label, external_ref, url, is_primary) as (
  values
    ('calendar-platform','supabase','Calendar Platform Supabase','tkvpnkxchkhcftttdyos',null,true),
    ('yritystiedot','supabase','YritystenTiedot Supabase','porkfghjezygajprlwtn',null,true),
    ('nordic-bottle-index','supabase','Nordic Bottle Index Supabase','ltesbbbjjyfobpydlryg',null,true),
    ('digiapu247','supabase','Digiapu247 Supabase','grjoerwgsrtwkdluojrq',null,true),

    ('calendar-platform','lovable','Calendar Platform Lovable','e6b45af4-303a-4a3b-8aa4-0cf598c5ea21','https://lovable.dev/projects/e6b45af4-303a-4a3b-8aa4-0cf598c5ea21',false),
    ('yritystiedot','lovable','YritystenTiedot Lovable','e3d519a9-31b6-48e5-80a4-7686c750546f','https://lovable.dev/projects/e3d519a9-31b6-48e5-80a4-7686c750546f',false),
    ('nordic-bottle-index','lovable','Nordic Bottle Index Lovable','7e3d510a-c900-4688-8147-34220f433d28','https://lovable.dev/projects/7e3d510a-c900-4688-8147-34220f433d28',false),
    ('pelovio','lovable','Pelovio Lovable','03c16eee-1ad0-403e-a2a0-74ee01958bb7','https://lovable.dev/projects/03c16eee-1ad0-403e-a2a0-74ee01958bb7',true),
    ('maistio','lovable','Maistio Helsinki Discover Lovable','449e4f31-2cf1-45d7-b3d5-1b4c39039fb5','https://lovable.dev/projects/449e4f31-2cf1-45d7-b3d5-1b4c39039fb5',false),
    ('cala-europe','lovable','Cala Europe Discovery Lovable','adbc4f2f-5a69-41d4-ab96-fd9a180aab17','https://lovable.dev/projects/adbc4f2f-5a69-41d4-ab96-fd9a180aab17',false),
    ('rail-atlas','lovable','Rail Atlas Lovable','cffed7ca-adce-4344-982e-230e607025c6','https://lovable.dev/projects/cffed7ca-adce-4344-982e-230e607025c6',false),
    ('sprinkler-rfq-platform','lovable','Fire Sprinkler Hub Lovable','861026d9-38b8-4d3e-bb05-250fc4ab1080','https://lovable.dev/projects/861026d9-38b8-4d3e-bb05-250fc4ab1080',false)
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
