import app from "https://raw.githubusercontent.com/meterionops/meterion-hq/e6eb9ad3e33c08f17e55d117377f07d1d8f95df0/supabase/functions/control-room-web-v1/index.ts";

const FRONTEND_URL = "https://meterion-control-room-web.onrender.com/";
const SUPABASE_REDIRECT_URL = "https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-web-v1";

function redirectTarget(request: Request): string {
  const incoming = new URL(request.url);
  const target = new URL(FRONTEND_URL);
  target.search = incoming.search;
  return target.toString();
}

async function rewriteMagicLinkRequest(request: Request): Promise<Request> {
  const text = await request.clone().text();
  let parsed: unknown;
  try {
    parsed = JSON.parse(text || "{}");
  } catch {
    return request;
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return request;
  const body = parsed as Record<string, unknown>;
  if (body.action !== "send_magic_link") return request;
  body.redirect_to = SUPABASE_REDIRECT_URL;
  const headers = new Headers(request.headers);
  headers.delete("content-length");
  headers.set("content-type", "application/json");
  return new Request(request.url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

function enhanceProjectsHtml(html: string): string {
  let out = html;

  out = out.replace(
    "</style>",
    ".tag.live{background:#e8f3ec;color:#1f6b46;border-color:#c9dfd1;font-weight:760}.section.operating>.section-head h2{color:#1f6b46}.project-tabs{display:flex;gap:8px;margin:22px 0 4px;padding-bottom:10px;border-bottom:1px solid var(--line);flex-wrap:wrap}.project-tab{appearance:none;border:1px solid var(--line);background:#f7f8f6;color:#526158;border-radius:999px;padding:8px 13px;font-size:13px;font-weight:720}.project-tab:hover{background:#eef2ee}.project-tab.active{background:var(--accent);border-color:var(--accent);color:#fff}.project-panel[hidden]{display:none!important}.project-panel{padding-top:2px}.project-tab .count{opacity:.72;margin-left:6px;font-weight:650}.control-block{margin:26px 0 30px;padding:18px 20px;border:1px solid var(--line);border-radius:14px;background:#fafbf9}.control-head{display:flex;justify-content:space-between;gap:16px;align-items:flex-start;margin-bottom:14px}.control-head h2{margin:0;font-size:16px}.control-grid{display:grid;grid-template-columns:150px 1fr;gap:9px 20px}.control-grid dt{font-size:12px;color:var(--muted)}.control-grid dd{margin:0;line-height:1.45}.control-link{color:#214b34;text-decoration:none;font-weight:700}.control-link:hover{text-decoration:underline}@media(max-width:760px){.control-grid{grid-template-columns:1fr;gap:3px}.control-grid dt{margin-top:8px}}</style>",
  );

  const projectRow = String.raw`let projectsTab='build';
function modeTag(p){const m=p.operating_mode||'';if(!m)return '';if(m==='operate')return tag('PUBLISHED','live');if(m==='build')return tag('BUILD');if(m==='idea')return tag('IDEA','warn');if(m==='delivery')return tag('DELIVERY');if(m==='paused')return tag('PAUSED','warn');if(m==='system')return tag('SYSTEM');return tag('MODE ?','warn')}
function projectRow(p){return '<div class="row"><div class="row-top"><div><h3>'+esc(p.name)+'</h3><p>'+esc(p.current_focus||p.goal||'No current focus recorded.')+'</p></div><button class="open" data-project="'+esc(p.project_key)+'">Open</button></div><div class="meta">'+modeTag(p)+tag(p.portfolio_class||p.projects_section||'UNCONFIRMED')+tag(p.autonomy_state||'state missing',p.autonomy_state==='owner_needed'?'attn':'')+tag(p.state_freshness||'missing',p.state_freshness==='fresh'?'ok':'warn')+(p.next_gate?tag('Next: '+p.next_gate,p.gate_status==='blocked'?'attn':(p.gate_status==='passed'?'ok':'')):'')+(p.founder_attention_required?tag('Founder attention','attn'):'')+'</div></div>'}
function setProjectsTab(tab){projectsTab=tab;document.querySelectorAll('[data-project-panel]').forEach(el=>{el.hidden=el.dataset.projectPanel!==tab});document.querySelectorAll('[data-project-tab]').forEach(el=>{el.classList.toggle('active',el.dataset.projectTab===tab);el.setAttribute('aria-selected',String(el.dataset.projectTab===tab))})}
function wireProjectTabs(){document.querySelectorAll('[data-project-tab]').forEach(b=>b.onclick=()=>setProjectsTab(b.dataset.projectTab))}`;

  out = out.replace(
    /function projectRow\(p\)\{[\s\S]*?\}\nfunction wireProjects/,
    `${projectRow}\nfunction wireProjects`,
  );

  const renderProjects = String.raw`async function renderProjects(){const [overviewRaw,rowsRaw]=await Promise.all([read('get_projects_overview'),read('get_projects')]);const overview=first(overviewRaw)||{};const rows=arr(rowsRaw);projectsCache=rows;const active=rows.filter(r=>r.projects_section==='active_portfolio');const unclassified=rows.filter(r=>r.projects_section==='active_unclassified');const unconfirmed=rows.filter(r=>r.projects_section==='unconfirmed_identity');const operating=rows.filter(r=>(r.projects_section==='active_portfolio'||r.projects_section==='active_unclassified')&&r.operating_mode==='operate');const activeBuild=active.filter(r=>r.operating_mode==='build');const unclassifiedBuild=unclassified.filter(r=>r.operating_mode==='build');const other=rows.filter(r=>r.projects_section==='unconfirmed_identity'||((r.projects_section==='active_portfolio'||r.projects_section==='active_unclassified')&&!['operate','build'].includes(r.operating_mode)));let buildHtml='';for(const cls of ['CORE','EXPERIMENT','AUTOPILOT','MAINTENANCE','VAULT']){const items=activeBuild.filter(r=>r.portfolio_class===cls);if(!items.length)continue;buildHtml+='<section class="section"><div class="section-head"><h2>'+cls+' · BUILD</h2><span class="kicker">'+items.length+'</span></div>'+items.map(projectRow).join('')+'</section>'}if(unclassifiedBuild.length)buildHtml+='<section class="section"><div class="section-head"><h2>Active build · unclassified</h2><span class="kicker">'+unclassifiedBuild.length+'</span></div>'+unclassifiedBuild.map(projectRow).join('')+'</section>';if(!buildHtml)buildHtml='<div class="empty"><h2>No active build work.</h2><p>Published products are kept in their own operating tab.</p></div>';const publishedHtml=operating.length?'<section class="section operating"><div class="section-head"><h2>PUBLISHED / OPERATING</h2><span class="kicker">'+operating.length+'</span></div>'+operating.map(projectRow).join('')+'</section>':'<div class="empty"><h2>No published operating products.</h2></div>';const otherHtml=other.length?'<section class="section"><div class="section-head"><h2>Ideas / delivery / unconfirmed</h2><span class="kicker">'+other.length+'</span></div>'+other.map(projectRow).join('')+'</section>':'<div class="empty"><h2>No other project states.</h2></div>';let html='<div class="view-head"><div><div class="eyebrow">Projects</div><h1>Portfolio truth</h1><p class="intro">Build work is the default view. Published products stay in a separate operating tab so they do not compete for attention unless you open them.</p></div></div><div class="overview"><div><strong>'+esc(overview.build_count??(activeBuild.length+unclassifiedBuild.length))+'</strong><span>active build</span></div><div><strong>'+esc(overview.operating_count??operating.length)+'</strong><span>published / operating</span></div><div><strong>'+esc(other.length)+'</strong><span>other</span></div><div><strong>'+esc(overview.active_state_quality_exception_count??0)+'</strong><span>state exceptions</span></div></div><div class="project-tabs" role="tablist" aria-label="Project work mode"><button class="project-tab" data-project-tab="build" role="tab">Build <span class="count">'+esc(activeBuild.length+unclassifiedBuild.length)+'</span></button><button class="project-tab" data-project-tab="published" role="tab">Published <span class="count">'+esc(operating.length)+'</span></button><button class="project-tab" data-project-tab="other" role="tab">Other <span class="count">'+esc(other.length)+'</span></button></div><div class="project-panel" data-project-panel="build">'+buildHtml+'</div><div class="project-panel" data-project-panel="published" hidden>'+publishedHtml+'</div><div class="project-panel" data-project-panel="other" hidden>'+otherHtml+'</div>';document.getElementById('main').innerHTML=html;wireProjects();wireProjectTabs();setProjectsTab(projectsTab)}`;

  out = out.replace(
    /async function renderProjects\(\)\{[\s\S]*?\}\nasync function renderProjectDetail/,
    `${renderProjects}\nasync function renderProjectDetail`,
  );


  const renderProjectDetail = String.raw\`async function renderProjectDetail(key){const state=first(await read('get_project_state',{project_key:key}));const cached=projectsCache.find(p=>p.project_key===key);currentView='projects';updateNav();if(!state)return;const source=cached?.primary_connection_url?'<a class="source-link" target="_blank" rel="noreferrer" href="'+esc(cached.primary_connection_url)+'">Open source ↗</a>':esc(state.source_ref||'No source link');const controlLink=state.project_control_file_url?'<a class="control-link" target="_blank" rel="noreferrer" href="'+esc(state.project_control_file_url)+'">Open Project Control File ↗</a>':'Not linked';const jev=state.last_jev_decision?(state.last_jev_decision+(state.last_jev_confidence!=null?' · '+Math.round(Number(state.last_jev_confidence)*100)+'%':'')):'No recorded Jev decision';const stopGates=arr(state.stop_gates).join(' · ')||'None recorded';const lockedCount=arr(state.locked_decisions).length;const control='<section class="control-block"><div class="control-head"><div><div class="eyebrow">Project Control</div><h2>Execution boundary</h2></div>'+(state.next_gate?tag(state.gate_status||'open',state.gate_status==='blocked'?'attn':(state.gate_status==='passed'?'ok':'warn')):'')+'</div><dl class="control-grid"><dt>Current build</dt><dd>'+esc(state.current_build||state.current_focus||'—')+'</dd><dt>Definition of done</dt><dd>'+esc(state.definition_of_done||'—')+'</dd><dt>Next gate</dt><dd>'+esc(state.next_gate||'—')+'</dd><dt>Next autonomous run</dt><dd>'+esc(state.next_autonomous_run||state.next_best_action||'—')+'</dd><dt>Stop gates</dt><dd>'+esc(stopGates)+'</dd><dt>Locked decisions</dt><dd>'+esc(String(lockedCount))+'</dd><dt>Last Jev decision</dt><dd>'+esc(jev)+'</dd><dt>Control file</dt><dd>'+controlLink+'</dd></dl></section>';const pairs=[['Goal',state.goal],['Success definition',state.success_definition],['Phase',state.phase],['Current focus',state.current_focus],['Latest material result',state.last_material_result],['Next best action',state.next_best_action],['Blocker',state.blocker_summary||'None'],['Autonomy',String(state.autonomy_state||'')+(state.autonomy_reason?' — '+state.autonomy_reason:'')],['Founder attention',state.founder_attention_required?(state.founder_attention_reason||state.founder_gate):'None'],['Verification',(state.state_freshness||'missing')+' · '+fmtTime(state.verified_at)+' · '+(state.confidence||'')],['Source',source],['Canonical constraints',arr(state.canonical_constraints).join(' · ')||'None']];document.getElementById('main').innerHTML='<button class="open back" id="back">← Projects</button><div class="view-head"><div><div class="eyebrow">'+esc(state.portfolio_class||state.lifecycle_status||'Project')+'</div><h1>'+esc(state.name)+'</h1><p class="intro">Resume-anywhere orientation packet · state v'+esc(state.state_version??'—')+'</p></div></div>'+control+'<dl class="detail-grid">'+pairs.map(([a,b])=>'<dt>'+esc(a)+'</dt><dd>'+(a==='Source'?b:esc(b??'—'))+'</dd>').join('')+'</dl>';document.getElementById('back').onclick=()=>go('projects')}\`;
  out = out.replace(
    /async function renderProjectDetail\(key\)\{[\s\S]*?\}\nasync function renderAi/,
    \`\${renderProjectDetail}\nasync function renderAi\`,
  );

  return out;
}

async function renderProxy(request: Request): Promise<Response> {
  const response = await app.fetch(request);
  const contentType = response.headers.get("content-type") ?? "";
  if (!response.ok || !contentType.includes("text/html")) return response;

  const body = enhanceProjectsHtml(await response.text());
  const headers = new Headers(response.headers);
  headers.set("content-type", "text/html; charset=utf-8");
  headers.set("cache-control", "no-store");
  return new Response(body, {
    status: response.status,
    headers,
  });
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "GET" || request.method === "HEAD") {
      const url = new URL(request.url);
      if (url.searchParams.get("render_proxy") === "1") return await renderProxy(request);
      return new Response(null, {
        status: 302,
        headers: {
          location: redirectTarget(request),
          "cache-control": "no-store",
          "referrer-policy": "no-referrer",
          "x-content-type-options": "nosniff",
        },
      });
    }
    if (request.method === "POST") return await app.fetch(await rewriteMagicLinkRequest(request));
    return await app.fetch(request);
  },
};
