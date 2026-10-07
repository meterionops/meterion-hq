// Called only after the existing signature + current Owner membership gate.
const projectFields = 'id project_key name kind goal portfolio_class lifecycle_status phase current_focus current_build next_gate next_best_action blocked blocker_summary founder_attention_required founder_attention_reason state_version verified_at state_committed_at tracking_changed_at tracking_fingerprint state_freshness state_missing classification_verified lifecycle_verified source_type source_ref project_control_file_url primary_connection_url recent_milestones'.split(' ');
const productFields = 'id parent_project_id name country_code country_name source_system source_project source_url source_updated_at captured_at connection_id repository_url reported_status publication_status publication_recorded_at next_milestone development_focus owner target_date search_console telemetry_state legal_pages_ready'.split(' ');
const domainFields = 'url registrar registrar_source source_label source_updated_at dns_provider dns_verified dns_checked_at dns_source nameservers'.split(' ');
const pick = (value, fields) => Object.fromEntries(fields.filter(k => Object.hasOwn(value || {}, k)).map(k => [k, value[k]]));
const object = value => value && typeof value === 'object' && !Array.isArray(value);
const https = value => { try { const url = new URL(value); return url.protocol === 'https:' && !url.username && !url.password ? url.href : null; } catch { return null; } };
function domains(values) {
  return (Array.isArray(values) ? values : []).filter(object).map(d => ({...pick(d, domainFields), url: https(d.url)})).filter(d => d.url);
}
export function buildOfficePortfolio(projects, connections, observedAt = new Date().toISOString()) {
  if (!Array.isArray(projects) || projects.length > 500 || !Array.isArray(connections) || connections.length > 2000) throw Error('office_source_invalid');
  const ids = new Set();
  const entries = projects.map(p => {
    if (!p?.id || ids.has(p.id)) throw Error('office_project_identity_invalid');
    ids.add(p.id);
    const linked = connections.filter(c => c.project_id === p.id);
    const products = linked.filter(c => object(c.metadata?.office_product)).map(c => {
      const product = c.metadata.office_product;
      if (product.parent_project_id !== p.id || !product.id) throw Error('office_product_binding_invalid');
      return {...pick(product, productFields), domains: domains(product.domains)};
    });
    if (new Set(products.map(c => c.id)).size !== products.length) throw Error('office_product_identity_invalid');
    const publication = linked.filter(c => typeof c.metadata?.published === 'boolean');
    const states = new Set(publication.map(c => c.metadata.published));
    const domainRecords = linked.filter(c => c.connection_type === 'production' && https(c.url)).map(c => ({
      ...pick(c.metadata, domainFields), url: https(c.url), source_updated_at: c.updated_at,
      source_label: 'Control Roomin projektikytkentä',
    }));
    return {...pick(p, projectFields), products, domains: domainRecords,
      publication_status: states.size === 1 ? (publication[0].metadata.published ? 'published' : 'unpublished') : 'unknown',
      publication_recorded_at: states.size === 1 ? publication.map(c => c.updated_at).filter(Boolean).sort().at(-1) || null : null,
    };
  });
  return {entries, observed_at: observedAt, source_system: 'control_room', source_project: 'cavvdvxicadgfftbziao', read_mode: 'current_source'};
}
export async function readOfficePortfolio(admin, organizationId) {
  if (!organizationId) throw Error("office_organization_required");
  const owned = await admin.from("control_room_projects").select("id", {count: 'exact'}).eq("organization_id", organizationId).limit(501);
  if (owned.error || !Array.isArray(owned.data) || owned.count !== owned.data.length || owned.data.length > 500) throw Error("office_ownership_unavailable");
  if (!owned.data.length) return buildOfficePortfolio([], []);
  const allowed = new Set(owned.data.map(p => p.id));
  const projects = await admin.rpc('control_room_get_project_tracking_surface_v1', {});
  if (projects.error || !Array.isArray(projects.data)) throw Error('office_projects_unavailable');
  projects.data = projects.data.filter(p => allowed.has(p.id));
  if (projects.data.length !== allowed.size) throw Error('office_project_coverage_invalid');
  if (!projects.data.length) return buildOfficePortfolio([], []);
  if (projects.data.length > 500) throw Error('office_project_limit');
  const connections = await admin.from('control_room_project_connections')
    .select('project_id,connection_type,url,metadata,updated_at', {count: 'exact'})
    .in('project_id', projects.data.map(p => p.id)).limit(2001);
  if (connections.error || !Array.isArray(connections.data) || connections.count !== connections.data.length) throw Error('office_connections_unavailable');
  return buildOfficePortfolio(projects.data, connections.data);
}
