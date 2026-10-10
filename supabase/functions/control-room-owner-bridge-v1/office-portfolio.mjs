// Called only after the existing signature + current Owner membership gate.
const projectFields = 'id project_key name kind goal portfolio_class lifecycle_status phase current_focus last_material_result definition_of_done source_ref current_build next_gate next_best_action blocked blocker_summary founder_attention_required founder_attention_reason state_version verified_at state_committed_at tracking_changed_at tracking_fingerprint state_freshness state_missing classification_verified lifecycle_verified source_type source_ref project_control_file_url primary_connection_url recent_milestones'.split(' ');
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
  const portfolio = buildOfficePortfolio(projects.data, connections.data);
  // Query only projects authorized above; never expose worker inputs, secrets or execution tokens.
  const work = await admin.from('control_room_project_work_units_v1')
    .select('id,project_id,work_unit_key,objective,definition_of_done,status,metadata,updated_at,completed_at', {count:'exact'})
    .in('project_id', projects.data.map(p => p.id)).order('updated_at', {ascending:false}).limit(1001);
  const available = !work.error && Array.isArray(work.data) && work.count === work.data.length && work.data.length <= 1000;
  let runs = [], nodes = [], runtimeAvailable = available;
  if (available && work.data.length) {
    const rr = await admin.from('control_room_project_graph_runs_v1')
      .select('run_key,project_id,work_unit_id,status,updated_at,completed_at', {count:'exact'})
      .in('project_id', projects.data.map(p => p.id)).order('updated_at',{ascending:false}).limit(1001);
    runtimeAvailable = !rr.error && Array.isArray(rr.data) && rr.count === rr.data.length && rr.data.length <= 1000;
    if (runtimeAvailable) runs = rr.data.filter(r => allowed.has(r.project_id));
    if (runs.length) {
      const nr = await admin.from('control_room_project_graph_nodes_v1')
        .select('graph_run_key,node_key,node_type,status,result,evidence,completed_at,heartbeat_at,lease_expires_at', {count:'exact'})
        .in('graph_run_key', runs.map(r => r.run_key)).limit(5001);
      runtimeAvailable = !nr.error && Array.isArray(nr.data) && nr.count === nr.data.length && nr.data.length <= 5000;
      if (runtimeAvailable) nodes = nr.data;
    }
  }
  for (const p of portfolio.entries) {
    p.work_status = available ? 'available' : 'unavailable';
    p.work_units = available ? work.data.filter(w => w.project_id === p.id).map(w => {
      const run = runs.find(r => r.work_unit_id === w.id && r.project_id === p.id);
      const ns = run ? nodes.filter(n => n.graph_run_key === run.run_key) : [];
      const verified = ns.filter(n => n.node_type === 'verifier' && n.status === 'completed' && object(n.result))
        .sort((a,b) => String(b.completed_at).localeCompare(String(a.completed_at)))[0];
      const result = verified ? publicResult(verified.result) : null;
      const heartbeat = ns.filter(n => ['running','verifying'].includes(n.status) && Date.parse(n.lease_expires_at) > Date.now())
        .map(n => n.heartbeat_at).filter(Boolean).sort().at(-1) || null;
      return {...pick(w, ['id','work_unit_key','objective','definition_of_done','status','updated_at','completed_at']),
        runtime_status: runtimeAvailable ? (run?.status || 'not_linked') : 'unavailable',
        run_key: run?.run_key || null, heartbeat_at: heartbeat, result,
        checkpoint: ns.filter(n => n.status === 'completed').map(n => n.node_key),
        maintenance: object(w.metadata?.office_maintenance) ? pickText(w.metadata.office_maintenance,
          ['automation_id','schedule_label','next_expected_at','schedule_recorded_at','pilot_end_at']) : null};
    }) : [];
  }
  return portfolio;
}

export function publicResult(value) {
  const textFields = ['summary','outcome','verified_at','next_action','observed_at','source_project','verification_method','cost_status'];
  const result = Object.fromEntries(textFields.filter(k => typeof value[k] === 'string').map(k => [k,value[k].slice(0,5000)]));
  for (const key of ['alerts','checks','source_tables']) result[key] = Array.isArray(value[key]) ? value[key].filter(x=>typeof x==='string').slice(0,20).map(x=>x.slice(0,1000)) : [];
  result.countries = Array.isArray(value.countries) ? value.countries.filter(object).slice(0,4).map(c=>pickText(c,['country_code','latest_fetch','latest_metric_date','search_console'])) : [];
  return result;
}

function pickText(value, fields) { return Object.fromEntries(fields.filter(k=>typeof value[k]==='string').map(k=>[k,value[k].slice(0,5000)])); }
