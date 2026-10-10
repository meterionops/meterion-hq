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
      payments: publicPayments(linked.find(c => c.connection_type === 'supabase' && object(c.metadata?.office_payments))?.metadata.office_payments),
      gsc: publicGsc(linked.find(c => c.connection_type === 'supabase' && object(c.metadata?.office_gsc))?.metadata.office_gsc),
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
  for (const p of portfolio.entries) {
    p.work_status = available ? 'available' : 'unavailable';
    p.work_units = available ? work.data.filter(w => w.project_id === p.id).map(w => {
      const saved = w.metadata?.office_result;
      const verified = w.status === 'completed' && object(saved)
        && typeof saved.summary === 'string' && saved.summary.trim()
        && Number.isFinite(Date.parse(saved.verified_at))
        && Number.isFinite(Date.parse(saved.observed_at))
        && Array.isArray(saved.checks) && saved.checks.length > 0
        && typeof saved.source_project === 'string'
        && Array.isArray(saved.source_tables) && saved.source_tables.length > 0;
      return {...pick(w, ['id','work_unit_key','objective','definition_of_done','status','updated_at','completed_at']),
        result: verified ? publicResult(saved) : null,
        next_action: typeof w.metadata?.next_action === 'string' ? w.metadata.next_action.slice(0,5000) : null,
        resume_note: typeof w.metadata?.resume_note === 'string' ? w.metadata.resume_note.slice(0,5000) : null,
        maintenance: object(w.metadata?.office_maintenance) ? pickText(w.metadata.office_maintenance,
          ['schedule_label','next_expected_at','schedule_recorded_at','pilot_end_at']) : null};
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


// Only public reporting fields; credentials and raw connector metadata never leave this reader.
export function publicGsc(value) {
  if (!object(value)) return null;
  const n = v => typeof v === 'number' && Number.isFinite(v) && v >= 0 ? v : null;
  const period = v => ({days:n(v?.days),clicks:n(v?.clicks),impressions:n(v?.impressions)});
  const rows = v => Array.isArray(v) ? v.filter(object).slice(0,5).map(r=>({...pickText(r,['label','period_start','period_end','fetched_at']),clicks:n(r.clicks),impressions:n(r.impressions)})) : [];
  return {...pickText(value,['status','observed_at','source_project','refresh_note','next_action','blocker']),
    sites:Array.isArray(value.sites)?value.sites.filter(object).slice(0,10).map(s=>({
      ...pickText(s,['site_id','country_code','property','registry_status','fetched_at','period_start','period_end']),
      current:period(s.current),previous:period(s.previous),top_queries:rows(s.top_queries),top_pages:rows(s.top_pages)
    })):[]};
}

export function publicPayments(value) {
  if (!object(value)) return null;
  const integer = v => Number.isSafeInteger(v) && v >= 0 ? v : null;
  const rows = v => Array.isArray(v) ? v.filter(object).slice(0,20).map(r => ({
    currency: typeof r.currency === 'string' && /^[a-z]{3}$/.test(r.currency) ? r.currency : null,
    payment_count: integer(r.payment_count), gross_minor: integer(r.gross_minor),
    refunded_payment_count: integer(r.refunded_payment_count), refund_minor: integer(r.refund_minor),
    net_before_fees_minor: integer(r.net_before_fees_minor),
  })) : [];
  return {...pickText(value,['status','observed_at','source','scope','refresh_note','next_action','blocker','latest_payment_at']),
    live_verified:value.live_verified===true, complete:value.complete===true,
    totals:rows(value.totals), service_totals:rows(value.service_totals),
    reconciliation: object(value.reconciliation) ? {
      ...pickText(value.reconciliation,['status','note','observed_at']),
      database_payment_count:integer(value.reconciliation.database_payment_count),
      stripe_payment_count:integer(value.reconciliation.stripe_payment_count),
      database_only_count:integer(value.reconciliation.database_only_count),
      stripe_only_count:integer(value.reconciliation.stripe_only_count)
    } : null
  };
}
