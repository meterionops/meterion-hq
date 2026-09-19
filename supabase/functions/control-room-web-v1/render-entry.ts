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


  const renderProjectDetail = String.raw`async function renderProjectDetail(key){const state=first(await read('get_project_state',{project_key:key}));const cached=projectsCache.find(p=>p.project_key===key);currentView='projects';updateNav();if(!state)return;const source=cached?.primary_connection_url?'<a class="source-link" target="_blank" rel="noreferrer" href="'+esc(cached.primary_connection_url)+'">Open source ↗</a>':esc(state.source_ref||'No source link');const controlLink=state.project_control_file_url?'<a class="control-link" target="_blank" rel="noreferrer" href="'+esc(state.project_control_file_url)+'">Open Project Control File ↗</a>':'Not linked';const jev=state.last_jev_decision?(state.last_jev_decision+(state.last_jev_confidence!=null?' · '+Math.round(Number(state.last_jev_confidence)*100)+'%':'')):'No recorded Jev decision';const stopGates=arr(state.stop_gates).join(' · ')||'None recorded';const lockedCount=arr(state.locked_decisions).length;const control='<section class="control-block"><div class="control-head"><div><div class="eyebrow">Project Control</div><h2>Execution boundary</h2></div>'+(state.next_gate?tag(state.gate_status||'open',state.gate_status==='blocked'?'attn':(state.gate_status==='passed'?'ok':'warn')):'')+'</div><dl class="control-grid"><dt>Current build</dt><dd>'+esc(state.current_build||state.current_focus||'—')+'</dd><dt>Definition of done</dt><dd>'+esc(state.definition_of_done||'—')+'</dd><dt>Next gate</dt><dd>'+esc(state.next_gate||'—')+'</dd><dt>Next autonomous run</dt><dd>'+esc(state.next_autonomous_run||state.next_best_action||'—')+'</dd><dt>Stop gates</dt><dd>'+esc(stopGates)+'</dd><dt>Locked decisions</dt><dd>'+esc(String(lockedCount))+'</dd><dt>Last Jev decision</dt><dd>'+esc(jev)+'</dd><dt>Control file</dt><dd>'+controlLink+'</dd></dl></section>';const pairs=[['Goal',state.goal],['Success definition',state.success_definition],['Phase',state.phase],['Current focus',state.current_focus],['Latest material result',state.last_material_result],['Next best action',state.next_best_action],['Blocker',state.blocker_summary||'None'],['Autonomy',String(state.autonomy_state||'')+(state.autonomy_reason?' — '+state.autonomy_reason:'')],['Founder attention',state.founder_attention_required?(state.founder_attention_reason||state.founder_gate):'None'],['Verification',(state.state_freshness||'missing')+' · '+fmtTime(state.verified_at)+' · '+(state.confidence||'')],['Source',source],['Canonical constraints',arr(state.canonical_constraints).join(' · ')||'None']];document.getElementById('main').innerHTML='<button class="open back" id="back">← Projects</button><div class="view-head"><div><div class="eyebrow">'+esc(state.portfolio_class||state.lifecycle_status||'Project')+'</div><h1>'+esc(state.name)+'</h1><p class="intro">Resume-anywhere orientation packet · state v'+esc(state.state_version??'—')+'</p></div></div>'+control+'<dl class="detail-grid">'+pairs.map(([a,b])=>'<dt>'+esc(a)+'</dt><dd>'+(a==='Source'?b:esc(b??'—'))+'</dd>').join('')+'</dl>';document.getElementById('back').onclick=()=>go('projects')}`;
  out = out.replace(
    /async function renderProjectDetail\(key\)\{[\s\S]*?\}\nasync function renderAi/,
    `${renderProjectDetail}\nasync function renderAi`,
  );

  return out;
}


function enhanceReiskaAssistantHtml(html: string): string {
  let out = html;
  out = out.replace("</style>", "\n/* Reiska Project Assistant v0.2 */\n.brand{display:flex;align-items:baseline;gap:8px}.brand-sub{font-size:11px;color:var(--muted);font-weight:650;letter-spacing:.08em;text-transform:uppercase}\n.reiska-hero{padding:22px 0 8px}.reiska-hero h1{font-size:clamp(34px,5vw,56px);margin-bottom:10px}.reiska-hero .intro{max-width:720px}\n.reiska-summary{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px;margin:18px 0 28px}.reiska-stat{background:#fff;border:1px solid var(--line);border-radius:16px;padding:16px}.reiska-stat strong{display:block;font-size:24px;letter-spacing:-.03em}.reiska-stat span{display:block;color:var(--muted);font-size:12px;margin-top:4px}\n.reiska-cards{display:grid;gap:14px}.reiska-card{background:#fff;border:1px solid var(--line);border-radius:18px;padding:20px;box-shadow:0 8px 26px rgba(23,32,27,.035)}.reiska-card.pilot{border-color:#c8d9cf}.reiska-card.attn{border-color:#ebc7c1;background:#fffaf8}.reiska-card .card-kicker{text-transform:uppercase;letter-spacing:.12em;font-size:10px;font-weight:800;color:#617067}.reiska-card h2{font-size:20px;margin:6px 0 8px}.reiska-card .recommendation{font-size:15px;line-height:1.55;margin:0 0 14px}.reiska-card .why{background:#f6f8f5;border-radius:12px;padding:12px 13px;font-size:13px;line-height:1.5;color:#4b584f}.reiska-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:14px}.reiska-actions button{border:1px solid var(--line);background:#fff;border-radius:10px;padding:10px 12px;font-weight:720;color:#254334;min-height:44px}.reiska-actions .primary-action{background:var(--accent);border-color:var(--accent);color:#fff}.reiska-actions .quiet{color:var(--muted)}\n.reiska-note{font-size:12px;color:var(--muted);line-height:1.5}.reiska-good{color:#27623d}.reiska-warn{color:#7a4b13}.reiska-empty{background:#fff;border:1px dashed #cdd6cf;border-radius:16px;padding:22px;color:var(--muted)}\n.assistant-panel{background:#fff;border:1px solid var(--line);border-radius:18px;padding:20px;margin-bottom:16px}.assistant-panel h2{font-size:18px;margin-bottom:8px}.quick-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;margin-top:14px}.quick-grid button{min-height:52px;border:1px solid var(--line);background:#f8faf8;border-radius:12px;text-align:left;padding:12px;font-weight:700;color:#243b2e}.assistant-answer{margin-top:14px;background:#eef4ef;border-radius:14px;padding:15px;line-height:1.55}.assistant-answer h3{margin-bottom:6px}.assistant-answer p:last-child{margin-bottom:0}.assistant-project-select{width:100%;border:1px solid #cbd3cd;border-radius:10px;padding:12px 13px;background:#fff;margin:8px 0 0}.policy-row{display:flex;gap:10px;align-items:flex-start;padding:10px 0;border-top:1px solid var(--line)}.policy-dot{width:8px;height:8px;border-radius:50%;background:#2c7a4b;margin-top:6px;flex:0 0 auto}\n.task-packet{margin-top:12px;background:#f8f9f7;border:1px solid var(--line);border-radius:12px;padding:13px;white-space:pre-wrap;font-size:13px;line-height:1.45}.toast{position:fixed;right:20px;bottom:22px;z-index:40;background:#173c2a;color:#fff;padding:11px 14px;border-radius:12px;box-shadow:0 12px 28px rgba(0,0,0,.18);font-size:13px}\n.project-assistant-block{margin:0 0 22px;background:#fff;border:1px solid #c8d9cf;border-radius:18px;padding:18px}.project-assistant-block h2{margin:4px 0 8px;font-size:19px}.project-assistant-block p{line-height:1.55}.project-assistant-block .why{font-size:13px;color:#4d5b52;background:#f5f8f5;border-radius:11px;padding:11px 12px}\n@media(max-width:760px){\n body{padding-bottom:calc(78px + env(safe-area-inset-bottom));overflow-x:hidden}\n .mobile-head{position:fixed;top:auto;bottom:0;left:0;right:0;z-index:30;background:rgba(250,251,249,.96);backdrop-filter:blur(14px);border-top:1px solid var(--line);border-bottom:0;padding:7px max(8px,env(safe-area-inset-right)) calc(7px + env(safe-area-inset-bottom)) max(8px,env(safe-area-inset-left));display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:4px;overflow:visible}\n .mobile-head button{min-height:48px;padding:6px 4px;border-radius:10px;font-size:12px;font-weight:720;line-height:1.15;white-space:normal}\n .main{padding:22px 14px 30px;max-width:none}\n .reiska-hero{padding-top:4px}.reiska-hero h1{font-size:38px}\n .reiska-summary{grid-template-columns:repeat(3,minmax(0,1fr));gap:7px;margin:14px 0 22px}.reiska-stat{padding:12px 10px;border-radius:13px}.reiska-stat strong{font-size:20px}.reiska-stat span{font-size:10px}\n .reiska-card{padding:16px;border-radius:16px}.reiska-card h2{font-size:18px}.reiska-actions{display:grid;grid-template-columns:1fr 1fr}.reiska-actions button{width:100%;min-height:48px}.reiska-actions .primary-action{grid-column:1/-1}\n .quick-grid{grid-template-columns:1fr}.quick-grid button{min-height:54px}\n .assistant-panel{padding:16px;border-radius:16px}.project-assistant-block{padding:16px;border-radius:16px}\n .view-head{margin-bottom:18px}.view-head h1{font-size:28px}.row{padding:16px 0}.row-top{display:block}.row-top .open{display:inline-flex;min-height:44px;align-items:center;margin-top:8px}.project-tabs{overflow-x:auto;flex-wrap:nowrap;scrollbar-width:none}.project-tab{white-space:nowrap;min-height:42px}\n .toast{left:14px;right:14px;bottom:calc(88px + env(safe-area-inset-bottom));text-align:center}\n}\n" + "</style>");
  out = out.replace('<div class="brand">Meterion Control Room</div>', '<div class="brand"><strong>Reiska</strong><span class="brand-sub">Meterion</span></div>');
  out = out.replace(
    /function navButtons\(\)\{[\s\S]*?\}\nfunction updateNav/,
    "function navButtons(){return ['today','projects','ai','system'].map(v=>'<button data-view=\\\"'+v+'\\\" class=\\\"'+(v===currentView?'active':'')+'\\\">'+({today:'Tänään',projects:'Projektit',ai:'Keskustele',system:'Asetukset'}[v])+'</button>').join('')}\\nfunction updateNav"
  );

  const helpers = String.raw`
const REISKA_PILOTS=new Set(['rail-atlas','maistio']);
const REISKA_SNOOZE_KEY='reiska-snooze-v02';
function reiskaSnoozes(){try{return JSON.parse(localStorage.getItem(REISKA_SNOOZE_KEY)||'{}')}catch{return {}}}
function isReiskaSnoozed(key){const x=reiskaSnoozes()[key];return Number(x||0)>Date.now()}
function snoozeReiska(key){const s=reiskaSnoozes();s[key]=Date.now()+24*60*60*1000;localStorage.setItem(REISKA_SNOOZE_KEY,JSON.stringify(s));toast('Piilotettu 24 tunniksi');go('today')}
function assistantPriority(p){
  let n=0;
  if(p.founder_attention_required)n+=100;
  if(p.blocked)n+=70;
  if(p.gate_status==='blocked')n+=65;
  if(REISKA_PILOTS.has(p.project_key))n+=40;
  if(p.portfolio_class==='CORE')n+=24;
  if(p.operating_mode==='build')n+=12;
  if(p.state_freshness==='fresh')n+=8;
  if(p.state_freshness==='stale'||p.state_freshness==='missing')n-=14;
  return n;
}
function reiskaWhy(p){
  const bits=[];
  if(p.current_build)bits.push('Nykyinen työ: '+p.current_build+'.');
  if(p.next_gate)bits.push('Seuraava portti: '+p.next_gate+(p.gate_status?' ('+p.gate_status+')':'')+'.');
  if(p.state_freshness)bits.push('Projektitila on '+p.state_freshness+'.');
  return bits.join(' ')||'Suositus perustuu Control Roomin viimeisimpään projektitilaan.';
}
function reiskaCard(p){
  const cls='reiska-card '+(REISKA_PILOTS.has(p.project_key)?'pilot ':'')+(p.founder_attention_required?'attn':'');
  return '<article class="'+cls+'"><div class="card-kicker">'+(p.founder_attention_required?'Tarvitsen päätöksesi':'Suosittelen seuraavaksi')+'</div><h2>'+esc(p.name)+'</h2><p class="recommendation">'+esc(p.next_best_action||'Tarkista projektin nykytila ennen seuraavaa työerää.')+'</p><div class="why">'+esc(reiskaWhy(p))+'</div><div class="reiska-actions"><button class="primary-action" data-prepare="'+esc(p.project_key)+'">Valmistele työ</button><button data-project="'+esc(p.project_key)+'">Avaa projekti</button><button class="quiet" data-snooze="'+esc(p.project_key)+'">Ei nyt</button></div></article>'
}
function toast(text){document.querySelector('.toast')?.remove();const el=document.createElement('div');el.className='toast';el.textContent=text;document.body.appendChild(el);setTimeout(()=>el.remove(),2600)}
async function getAssistantProject(key){let p=projectsCache.find(x=>x.project_key===key);if(p)return p;const rows=arr(await read('get_projects'));projectsCache=rows;return rows.find(x=>x.project_key===key)}
function makeWorkPacket(p){
  return ['Jatka projektia '+p.name+'.',
    'Tavoite: '+(p.goal||'tarkista Project Control File / lähdejärjestelmä'),
    'Nykyinen työ: '+(p.current_build||p.current_focus||'tarkista nykytila'),
    'Seuraava hyödyllinen työ: '+(p.next_best_action||'tarkista nykytila ja ehdota seuraava rajattu työ'),
    'Valmistumiskriteeri: '+(p.definition_of_done||p.success_definition||'tulos on todennettu lähdejärjestelmistä'),
    'Seuraava portti: '+(p.next_gate||'ei kirjattu'),
    'Rajat: '+(arr(p.stop_gates).join('; ')||'noudata projektin lukittuja rajoja ja pyydä päätös vain aidossa stop-gatessa'),
    'Käytä nykyisiä lähdejärjestelmiä. Älä avaa strategiaa uudelleen ilman uutta näyttöä. Lopuksi päivitä vain todennettu materiaalinen muutos Control Roomiin.'
  ].join('\\n');
}
async function prepareWork(key){
  const p=await getAssistantProject(key);if(!p)return toast('Projektia ei löytynyt');
  const packet=makeWorkPacket(p);
  const old=document.getElementById('task-packet-panel');if(old)old.remove();
  const panel=document.createElement('section');panel.id='task-packet-panel';panel.className='assistant-panel';panel.innerHTML='<div class="eyebrow">Valmis toimeksianto</div><h2>'+esc(p.name)+'</h2><p class="reiska-note">Reiska valmisteli rajatun työpaketin. Sen kopioiminen ei käynnistä toteutusta.</p><div class="task-packet">'+esc(packet)+'</div><div class="reiska-actions"><button class="primary-action" id="copy-packet">Kopioi ChatGPT:lle</button><button id="close-packet">Sulje</button></div>';
  document.getElementById('main').appendChild(panel);panel.scrollIntoView({behavior:'smooth',block:'start'});
  document.getElementById('copy-packet').onclick=async()=>{try{await navigator.clipboard.writeText(packet);toast('Työpaketti kopioitu')}catch{toast('Kopiointi ei onnistunut — valitse teksti käsin')}};
  document.getElementById('close-packet').onclick=()=>panel.remove();
}
function wireReiskaActions(){
  document.querySelectorAll('[data-project]').forEach(b=>b.onclick=()=>renderProjectDetail(b.dataset.project));
  document.querySelectorAll('[data-prepare]').forEach(b=>b.onclick=()=>prepareWork(b.dataset.prepare));
  document.querySelectorAll('[data-snooze]').forEach(b=>b.onclick=()=>snoozeReiska(b.dataset.snooze));
}
async function assistantRows(){const rows=arr(await read('get_projects'));projectsCache=rows;return rows.filter(p=>p.lifecycle_status==='active')}
function reiskaAnswer(title,body){const el=document.getElementById('assistant-answer');if(!el)return;el.innerHTML='<h3>'+esc(title)+'</h3><p>'+esc(body)+'</p>'}
async function answerQuick(kind){
  const rows=await assistantRows();const active=rows.filter(p=>!isReiskaSnoozed(p.project_key));
  const ranked=[...active].sort((a,b)=>assistantPriority(b)-assistantPriority(a));
  if(kind==='focus'){const p=ranked[0];return reiskaAnswer('Keskity tähän',p?((p.name)+': '+(p.next_best_action||p.current_focus||'tarkista nykytila')):'Tänään ei ole selvää seuraavaa nostoa.')}
  if(kind==='needs'){const list=active.filter(p=>p.founder_attention_required||p.blocked||p.gate_status==='blocked');return reiskaAnswer('Tarvitsee sinua',list.length?list.map(p=>p.name+': '+(p.founder_attention_reason||p.blocker_summary||p.next_gate||'päätös tarvitaan')).join(' · '):'Yksikään aktiivinen projekti ei tällä hetkellä ilmoita pakollista founder-päätöstä.')}
  if(kind==='prepare'){const p=ranked.find(p=>REISKA_PILOTS.has(p.project_key))||ranked[0];if(!p)return reiskaAnswer('Valmisteltavaa ei löytynyt','Projektitila ei tarjoa nyt rajattua seuraavaa työtä.');reiskaAnswer('Voin valmistella tämän',p.name+': '+(p.next_best_action||'tarkista nykytila'));setTimeout(()=>prepareWork(p.project_key),50);return}
  if(kind==='changed'){const changed=active.filter(p=>p.recent_material_change||p.latest_event_summary).slice(0,3);return reiskaAnswer('Viimeisimmät olennaiset muutokset',changed.length?changed.map(p=>p.name+': '+(p.latest_event_summary||p.last_material_result||'tila muuttui')).join(' · '):'Control Roomissa ei ole nyt uutta materiaalista muutosta nostettavaksi.')}
}
async function answerProject(){const key=document.getElementById('assistant-project')?.value;if(!key)return;const p=await getAssistantProject(key);if(!p)return;reiskaAnswer(p.name,(p.next_best_action||'Tarkista nykytila')+' '+reiskaWhy(p))}
\`;

  const renderToday = String.raw`async function renderToday(){
    const rows=await assistantRows();
    const active=rows.filter(p=>!isReiskaSnoozed(p.project_key));
    const attention=active.filter(p=>p.founder_attention_required||p.blocked||p.gate_status==='blocked');
    const ranked=[...active].sort((a,b)=>assistantPriority(b)-assistantPriority(a));
    const recs=[];for(const p of [...attention,...ranked]){if(!recs.some(x=>x.project_key===p.project_key))recs.push(p);if(recs.length===3)break}
    const fresh=rows.filter(p=>p.state_freshness==='fresh').length;
    let html='<div class="reiska-hero"><div class="eyebrow">Reiska · projektiassistentti</div><h1>Huomenta. Tässä olennaisin.</h1><p class="intro">Reiska pitää projektitilanteen koossa Control Roomin perusteella ja nostaa vain seuraavat hyödylliset asiat. Tekninen näyttö on projektin sisällä tarvittaessa.</p></div>'+
      '<div class="reiska-summary"><div class="reiska-stat"><strong>'+esc(rows.length)+'</strong><span>aktiivista</span></div><div class="reiska-stat"><strong>'+esc(attention.length)+'</strong><span>tarvitsee sinua</span></div><div class="reiska-stat"><strong>'+esc(fresh)+'</strong><span>tuore tila</span></div></div>';
    if(recs.length)html+='<div class="reiska-cards">'+recs.map(reiskaCard).join('')+'</div>';
    else html+='<div class="reiska-empty"><strong>Mitään olennaista ei tarvitse nostaa juuri nyt.</strong><p>Reiska ei keksi tekemistä vain näyttääkseen aktiiviselta.</p></div>';
    html+='<p class="reiska-note" style="margin-top:18px">Pilottiprojektit: Rail Atlas ja Maistio. Kaikki projektit näkyvät Projektit-näkymässä. “Ei nyt” piilottaa ehdotuksen tältä laitteelta 24 tunniksi.</p>';
    document.getElementById('main').innerHTML=html;wireReiskaActions()
  }\`;

  out = out.replace(
    /async function renderToday\(\)\{[\s\S]*?\}\nasync function renderProjects/,
    helpers + "\\n" + renderToday + "\\nasync function renderProjects"
  );

  const renderProjectDetail = String.raw`async function renderProjectDetail(key){
    const state=first(await read('get_project_state',{project_key:key}));const cached=projectsCache.find(p=>p.project_key===key);currentView='projects';updateNav();if(!state)return;
    const merged={...cached,...state,project_key:key};
    const source=cached?.primary_connection_url?'<a class="source-link" target="_blank" rel="noreferrer" href="'+esc(cached.primary_connection_url)+'">Avaa lähde ↗</a>':esc(state.source_ref||'Lähdelinkkiä ei ole');
    const controlLink=state.project_control_file_url?'<a class="control-link" target="_blank" rel="noreferrer" href="'+esc(state.project_control_file_url)+'">Avaa Project Control File ↗</a>':'Ei linkitetty';
    const assistant='<section class="project-assistant-block"><div class="eyebrow">Reiskan suositus</div><h2>'+esc(state.next_best_action||'Tarkista projektin nykytila')+'</h2><div class="why">'+esc(reiskaWhy(merged))+'</div><div class="reiska-actions"><button class="primary-action" data-prepare="'+esc(key)+'">Valmistele työ</button><button class="quiet" data-snooze="'+esc(key)+'">Ei nyt</button></div></section>';
    const jev=state.last_jev_decision?(state.last_jev_decision+(state.last_jev_confidence!=null?' · '+Math.round(Number(state.last_jev_confidence)*100)+'%':'')):'Ei kirjattua Jev-päätöstä';
    const stopGates=arr(state.stop_gates).join(' · ')||'Ei kirjattuja';
    const control='<details class="control-block"><summary><strong>Tekniset ja ohjaustiedot</strong> · '+esc(state.state_freshness||'unknown')+'</summary><dl class="control-grid" style="margin-top:14px"><dt>Nykyinen työ</dt><dd>'+esc(state.current_build||state.current_focus||'—')+'</dd><dt>Valmistumiskriteeri</dt><dd>'+esc(state.definition_of_done||'—')+'</dd><dt>Seuraava portti</dt><dd>'+esc(state.next_gate||'—')+'</dd><dt>Stop-gatet</dt><dd>'+esc(stopGates)+'</dd><dt>Jev</dt><dd>'+esc(jev)+'</dd><dt>Control file</dt><dd>'+controlLink+'</dd><dt>Lähde</dt><dd>'+source+'</dd></dl></details>';
    document.getElementById('main').innerHTML='<button class="open back" id="back">← Projektit</button><div class="view-head"><div><div class="eyebrow">'+esc(state.portfolio_class||state.lifecycle_status||'Projekti')+'</div><h1>'+esc(state.name)+'</h1><p class="intro">'+esc(state.current_focus||state.goal||'')+'</p></div></div>'+assistant+'<section class="section"><div class="section-head"><h2>Tilanne</h2><span class="kicker">tarkistettu '+esc(fmtTime(state.verified_at))+'</span></div><div class="row"><h3>Viimeisin olennainen tulos</h3><p>'+esc(state.last_material_result||state.latest_event_summary||'Ei kirjattua materiaalista muutosta.')+'</p></div><div class="row"><h3>Seuraava portti</h3><p>'+esc(state.next_gate||'Ei erillistä porttia kirjattu.')+'</p></div></section>'+control;
    document.getElementById('back').onclick=()=>go('projects');wireReiskaActions()
  }\`;
  out = out.replace(
    /async function renderProjectDetail\(key\)\{[\s\S]*?\}\nasync function renderAi/,
    renderProjectDetail + "\\nasync function renderAi"
  );

  const renderAssistant = String.raw`async function renderAi(){
    const rows=await assistantRows();const options=rows.sort((a,b)=>a.name.localeCompare(b.name)).map(p=>'<option value="'+esc(p.project_key)+'">'+esc(p.name)+'</option>').join('');
    document.getElementById('main').innerHTML='<div class="view-head"><div><div class="eyebrow">Keskustele</div><h1>Kysy Reiskalta projekteistasi</h1><p class="intro">Tämä näkymä vastaa Control Roomin projektitilasta. Se ei käynnistä työtä tai hyväksy päätöksiä.</p></div></div>'+
    '<section class="assistant-panel"><h2>Mitä haluat tietää?</h2><div class="quick-grid"><button data-ask="focus">Mihin keskityn nyt?</button><button data-ask="needs">Mikä tarvitsee minua?</button><button data-ask="prepare">Mitä voit valmistella?</button><button data-ask="changed">Mikä on muuttunut?</button></div><div id="assistant-answer" class="assistant-answer"><h3>Reiska on valmis.</h3><p>Valitse kysymys tai projekti. Vastaukset perustuvat tallennettuun projektitilaan, eivät vapaaseen arvaukseen.</p></div></section>'+
    '<section class="assistant-panel"><h2>Kysy yhdestä projektista</h2><label for="assistant-project">Projekti</label><select id="assistant-project" class="assistant-project-select">'+options+'</select><div class="reiska-actions"><button class="primary-action" id="ask-project">Mitä seuraavaksi?</button><button id="prepare-project">Valmistele työ</button></div></section>'+
    '<section class="assistant-panel"><div class="eyebrow">Tutkiminen</div><h2>Rajattu projektien ympärille</h2><div class="policy-row"><span class="policy-dot"></span><div><strong>Vain aktiivisiin projekteihin liittyvä</strong><p class="reiska-note">Ulkoinen tutkimus otetaan käyttöön vain, kun kysymys voi muuttaa projektin seuraavaa päätöstä tai työvaihetta. Automaattinen web-tutkimus ei vielä käynnisty tästä näkymästä.</p></div></div><div class="policy-row"><span class="policy-dot"></span><div><strong>Ei uusia projekteja tutkimuksen sivutuotteena</strong><p class="reiska-note">Löydös voi synnyttää pienen kokeiluehdotuksen, ei automaattista prioriteetin muutosta.</p></div></div></section>';
    document.querySelectorAll('[data-ask]').forEach(b=>b.onclick=()=>answerQuick(b.dataset.ask));
    document.getElementById('ask-project').onclick=answerProject;
    document.getElementById('prepare-project').onclick=()=>prepareWork(document.getElementById('assistant-project').value)
  }\`;
  out = out.replace(
    /async function renderAi\(\)\{[\s\S]*?\}\nasync function renderSystem/,
    renderAssistant + "\\nasync function renderSystem"
  );
  return out;
}

async function renderProxy(request: Request): Promise<Response> {
  const response = await app.fetch(request);
  const contentType = response.headers.get("content-type") ?? "";
  if (!response.ok || !contentType.includes("text/html")) return response;

  const body = enhanceReiskaAssistantHtml(enhanceProjectsHtml(await response.text()));
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
