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
    ".tag.live{background:#e8f3ec;color:#1f6b46;border-color:#c9dfd1;font-weight:760}.section.operating>.section-head h2{color:#1f6b46}</style>",
  );

  const projectRow = String.raw`function modeTag(p){const m=p.operating_mode||'';if(!m)return '';if(m==='operate')return tag('PUBLISHED','live');if(m==='build')return tag('BUILD');if(m==='idea')return tag('IDEA','warn');if(m==='delivery')return tag('DELIVERY');if(m==='paused')return tag('PAUSED','warn');if(m==='system')return tag('SYSTEM');return tag('MODE ?','warn')}
function projectRow(p){return '<div class="row"><div class="row-top"><div><h3>'+esc(p.name)+'</h3><p>'+esc(p.current_focus||p.goal||'No current focus recorded.')+'</p></div><button class="open" data-project="'+esc(p.project_key)+'">Open</button></div><div class="meta">'+modeTag(p)+tag(p.portfolio_class||p.projects_section||'UNCONFIRMED')+tag(p.autonomy_state||'state missing',p.autonomy_state==='owner_needed'?'attn':'')+tag(p.state_freshness||'missing',p.state_freshness==='fresh'?'ok':'warn')+(p.founder_attention_required?tag('Founder attention','attn'):'')+'</div></div>'}`;

  out = out.replace(
    /function projectRow\(p\)\{[\s\S]*?\}\nfunction wireProjects/,
    `${projectRow}\nfunction wireProjects`,
  );

  const renderProjects = String.raw`async function renderProjects(){const [overviewRaw,rowsRaw]=await Promise.all([read('get_projects_overview'),read('get_projects')]);const overview=first(overviewRaw)||{};const rows=arr(rowsRaw);projectsCache=rows;const active=rows.filter(r=>r.projects_section==='active_portfolio');const unclassified=rows.filter(r=>r.projects_section==='active_unclassified');const unconfirmed=rows.filter(r=>r.projects_section==='unconfirmed_identity');const operating=rows.filter(r=>(r.projects_section==='active_portfolio'||r.projects_section==='active_unclassified')&&r.operating_mode==='operate');const activeBuild=active.filter(r=>r.operating_mode!=='operate');const unclassifiedBuild=unclassified.filter(r=>r.operating_mode!=='operate');let html='<div class="view-head"><div><div class="eyebrow">Projects</div><h1>Portfolio truth</h1><p class="intro">Published operation and active build work are shown separately.</p></div></div><div class="overview"><div><strong>'+esc(overview.operating_count??operating.length)+'</strong><span>published / operating</span></div><div><strong>'+esc(overview.build_count??(activeBuild.length+unclassifiedBuild.length))+'</strong><span>active build</span></div><div><strong>'+esc(overview.active_portfolio_count??active.length)+'</strong><span>confirmed active</span></div><div><strong>'+esc(overview.active_unclassified_count??unclassified.length)+'</strong><span>active unclassified</span></div><div><strong>'+esc(overview.unconfirmed_identity_count??unconfirmed.length)+'</strong><span>awaiting confirmation</span></div></div>';if(operating.length)html+='<section class="section operating"><div class="section-head"><h2>PUBLISHED / OPERATING</h2><span class="kicker">'+operating.length+'</span></div>'+operating.map(projectRow).join('')+'</section>';for(const cls of ['CORE','EXPERIMENT','AUTOPILOT','MAINTENANCE','VAULT']){const items=activeBuild.filter(r=>r.portfolio_class===cls);if(!items.length)continue;html+='<section class="section"><div class="section-head"><h2>'+cls+' · BUILD</h2><span class="kicker">'+items.length+'</span></div>'+items.map(projectRow).join('')+'</section>'}if(unclassifiedBuild.length)html+='<section class="section"><div class="section-head"><h2>Active build · unclassified</h2><span class="kicker">'+unclassifiedBuild.length+'</span></div>'+unclassifiedBuild.map(projectRow).join('')+'</section>';if(unconfirmed.length)html+='<details class="section"><summary>Needs lifecycle confirmation ('+unconfirmed.length+')</summary><div style="margin-top:12px">'+unconfirmed.map(projectRow).join('')+'</div></details>';document.getElementById('main').innerHTML=html;wireProjects()}`;

  out = out.replace(
    /async function renderProjects\(\)\{[\s\S]*?\}\nasync function renderProjectDetail/,
    `${renderProjects}\nasync function renderProjectDetail`,
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
