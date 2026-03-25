insert into public.system_document_sources (
  slug,
  source_repo,
  source_branch,
  source_path,
  source_mode,
  project_key,
  is_enabled
) values (
  'cityos-root-index',
  'meterionops/meterion-hq',
  'main',
  'docs/cityos/index.md',
  'file',
  'cityos',
  true
);
