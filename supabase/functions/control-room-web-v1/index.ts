import { createClient } from "npm:@supabase/supabase-js@2";

const PROJECT_REF = "cavvdvxicadgfftbziao";
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const WEB_PATH = "/functions/v1/control-room-web-v1";
const API_V2_URL = `${SUPABASE_URL}/functions/v1/control-room-api-v2`;
const MAX_BODY_BYTES = 32_768;
const PROJECT_KEY_RE = /^[a-z0-9][a-z0-9-]*$/;

const READ_ACTIONS = new Set([
  "get_project_state",
  "get_projects",
  "get_projects_overview",
  "get_today",
  "get_owner_attention",
  "get_state_reconciliation",
]);

function publishableKey(): string {
  const named = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (named) {
    try {
      const parsed = JSON.parse(named) as Record<string, unknown>;
      if (typeof parsed.default === "string" && parsed.default.length > 0) return parsed.default;
    } catch {}
  }
  const fallback = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY");
  if (!fallback) throw new Error("missing_supabase_publishable_key");
  return fallback;
}

function secretKey(): string {
  const named = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (named) {
    try {
      const parsed = JSON.parse(named) as Record<string, unknown>;
      if (typeof parsed.default === "string" && parsed.default.length > 0) return parsed.default;
    } catch {}
  }
  const fallback = Deno.env.get("SUPABASE_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!fallback) throw new Error("missing_supabase_secret_key");
  return fallback;
}

const admin = createClient(SUPABASE_URL, secretKey(), {
  auth: { autoRefreshToken: false, persistSession: false },
});
const publicAuth = createClient(SUPABASE_URL, publishableKey(), {
  auth: { autoRefreshToken: false, persistSession: false },
});

type JsonObject = Record<string, unknown>;

type SessionContext = {
  userId: string;
  email: string;
  aal: string | null;
  token: string;
};

function json(status: number, body: JsonObject): Response {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
      "content-type": "application/json; charset=utf-8",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
    },
  });
}

function normalizedEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const email = value.trim().toLowerCase();
  if (!email || !email.includes("@") || email.length > 320) return null;
  return email;
}

function allowedReturnUrl(value: unknown): string | null {
  if (typeof value !== "string") return null;
  try {
    const url = new URL(value);
    if (url.origin !== SUPABASE_URL) return null;
    if (url.pathname !== WEB_PATH) return null;
    url.hash = "";
    return url.toString();
  } catch {
    return null;
  }
}

function bearer(request: Request): string | null {
  const authorization = request.headers.get("authorization") ?? "";
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

function jwtAal(token: string): string | null {
  try {
    const part = token.split(".")[1];
    if (!part) return null;
    const normalized = part.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
    const payload = JSON.parse(atob(padded)) as Record<string, unknown>;
    return typeof payload.aal === "string" ? payload.aal : null;
  } catch {
    return null;
  }
}

async function loginPolicy(email: string) {
  const { data, error } = await admin
    .from("control_room_login_allowlist")
    .select("email, active, require_mfa")
    .eq("email", email)
    .eq("active", true)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function sessionContext(request: Request): Promise<SessionContext> {
  const token = bearer(request);
  if (!token) throw new Error("missing_token");
  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user?.id || !data.user.email) throw new Error("invalid_session");
  const email = data.user.email.trim().toLowerCase();
  const policy = await loginPolicy(email);
  if (!policy) throw new Error("login_not_allowed");
  return {
    userId: data.user.id,
    email,
    aal: jwtAal(token),
    token,
  };
}

async function activeOperator(userId: string) {
  const { data, error } = await admin
    .from("control_room_operators")
    .select("user_id, role, active, require_mfa")
    .eq("user_id", userId)
    .eq("active", true)
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function requireOperator(request: Request): Promise<SessionContext & { role: string }> {
  const context = await sessionContext(request);
  if (context.aal !== "aal2") throw new Error("mfa_required");
  const operator = await activeOperator(context.userId);
  if (!operator) throw new Error("operator_not_enrolled");
  if (operator.require_mfa !== false && context.aal !== "aal2") throw new Error("mfa_required");
  return { ...context, role: operator.role };
}

async function parseBody(request: Request): Promise<JsonObject> {
  const contentLength = Number(request.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) throw new Error("request_too_large");
  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > MAX_BODY_BYTES) throw new Error("request_too_large");
  let parsed: unknown;
  try {
    parsed = JSON.parse(text || "{}");
  } catch {
    throw new Error("invalid_json");
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("invalid_request");
  return parsed as JsonObject;
}

function apiPayload(body: JsonObject): JsonObject {
  const action = body.api_action;
  if (typeof action !== "string" || !READ_ACTIONS.has(action)) throw new Error("unknown_read_action");
  const payload: JsonObject = { action };
  if (action === "get_project_state") {
    if (typeof body.project_key !== "string" || !PROJECT_KEY_RE.test(body.project_key)) throw new Error("invalid_project_key");
    payload.project_key = body.project_key;
  }
  if (action === "get_projects") {
    for (const key of ["projects_section", "portfolio_class", "state_freshness"] as const) {
      if (body[key] !== undefined && body[key] !== null && typeof body[key] !== "string") throw new Error("invalid_filter");
      if (typeof body[key] === "string" && body[key] !== "") payload[key] = body[key];
    }
  }
  if (action === "get_state_reconciliation") {
    if (body.due_only !== undefined && typeof body.due_only !== "boolean") throw new Error("invalid_filter");
    if (body.portfolio_class !== undefined && body.portfolio_class !== null && typeof body.portfolio_class !== "string") throw new Error("invalid_filter");
    payload.due_only = body.due_only ?? true;
    if (typeof body.portfolio_class === "string" && body.portfolio_class !== "") payload.portfolio_class = body.portfolio_class;
  }
  return payload;
}

async function proxyApiV2(payload: JsonObject): Promise<Response> {
  const secret = secretKey();
  const response = await fetch(API_V2_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "apikey": secret,
      "authorization": `Bearer ${secret}`,
    },
    body: JSON.stringify(payload),
  });
  const text = await response.text();
  return new Response(text, {
    status: response.status,
    headers: {
      "cache-control": "no-store",
      "content-type": response.headers.get("content-type") ?? "application/json; charset=utf-8",
      "x-content-type-options": "nosniff",
      "referrer-policy": "no-referrer",
    },
  });
}

async function handlePost(request: Request): Promise<Response> {
  let body: JsonObject;
  try {
    body = await parseBody(request);
  } catch (error) {
    const code = error instanceof Error ? error.message : "invalid_request";
    return json(code === "request_too_large" ? 413 : 400, { ok: false, code });
  }

  if (body.action === "send_magic_link") {
    const email = normalizedEmail(body.email);
    const redirectTo = allowedReturnUrl(body.redirect_to);
    if (!email || !redirectTo) return json(400, { ok: false, code: "invalid_request" });
    const policy = await loginPolicy(email);
    if (!policy) return json(403, { ok: false, code: "login_not_allowed" });
    const { error } = await publicAuth.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: redirectTo, shouldCreateUser: true },
    });
    if (error) return json(400, { ok: false, code: "magic_link_failed" });
    return json(200, { ok: true });
  }

  if (body.action === "session_status") {
    try {
      const context = await sessionContext(request);
      const operator = await activeOperator(context.userId);
      return json(200, {
        ok: true,
        email: context.email,
        aal: context.aal,
        operator_active: Boolean(operator),
        role: operator?.role ?? null,
        require_mfa: true,
      });
    } catch (error) {
      const code = error instanceof Error ? error.message : "session_error";
      const status = code === "login_not_allowed" ? 403 : 401;
      return json(status, { ok: false, code });
    }
  }

  if (body.action === "activate_first_operator") {
    let context: SessionContext;
    try {
      context = await sessionContext(request);
    } catch (error) {
      const code = error instanceof Error ? error.message : "invalid_session";
      return json(code === "login_not_allowed" ? 403 : 401, { ok: false, code });
    }
    if (context.aal !== "aal2") return json(403, { ok: false, code: "mfa_required" });

    const existing = await activeOperator(context.userId);
    if (existing) return json(200, { ok: true, role: existing.role, bootstrap: false });

    const { count, error: countError } = await admin
      .from("control_room_operators")
      .select("user_id", { count: "exact", head: true })
      .eq("active", true);
    if (countError) return json(500, { ok: false, code: "operator_check_failed" });
    if ((count ?? 0) > 0) return json(403, { ok: false, code: "operator_not_enrolled" });

    const policy = await loginPolicy(context.email);
    if (!policy || policy.require_mfa === false) return json(403, { ok: false, code: "bootstrap_not_allowed" });

    const { error: insertError } = await admin.from("control_room_operators").insert({
      user_id: context.userId,
      role: "owner",
      active: true,
      require_mfa: true,
    });
    if (insertError) return json(500, { ok: false, code: "operator_activation_failed" });
    return json(200, { ok: true, role: "owner", bootstrap: true });
  }

  if (body.action === "read") {
    try {
      await requireOperator(request);
      const payload = apiPayload(body);
      return await proxyApiV2(payload);
    } catch (error) {
      const code = error instanceof Error ? error.message : "read_failed";
      const status = code === "missing_token" || code === "invalid_session" ? 401 : 403;
      return json(status, { ok: false, code });
    }
  }

  return json(400, { ok: false, code: "unknown_action" });
}

function page(): string {
  const key = publishableKey();
  return `<!doctype html>
<html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>Meterion Control Room</title><meta name="robots" content="noindex,nofollow"/>
<style>
:root{color-scheme:light;font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;--bg:#f4f5f2;--panel:#fff;--ink:#17201b;--muted:#69766e;--line:#dde3de;--accent:#173c2a;--soft:#eef2ee;--warn:#7a4b13;--danger:#8a2d28}*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);min-height:100vh}button,input{font:inherit}button{cursor:pointer}.auth-wrap{min-height:100vh;display:grid;place-items:center;padding:24px}.auth-card{width:min(560px,100%);background:var(--panel);border:1px solid var(--line);border-radius:20px;padding:30px;box-shadow:0 18px 50px rgba(20,35,25,.07)}.eyebrow{text-transform:uppercase;letter-spacing:.13em;font-size:11px;font-weight:750;color:#617067}h1,h2,h3,p{margin-top:0}h1{font-size:30px;letter-spacing:-.035em;margin-bottom:10px}h2{font-size:22px;letter-spacing:-.025em}h3{font-size:15px}.intro,.muted{color:var(--muted);line-height:1.55}.panel{padding:18px;background:#f8f9f7;border:1px solid #e3e7e3;border-radius:14px}label{display:block;font-size:13px;font-weight:650;margin:14px 0 7px}input{width:100%;border:1px solid #cbd3cd;border-radius:10px;padding:12px 13px;background:#fff}.buttons{display:flex;gap:10px;margin-top:18px;flex-wrap:wrap}.btn{border:0;border-radius:10px;padding:10px 14px;font-weight:680}.primary{background:var(--accent);color:#fff}.secondary{background:#e9eeea;color:#223229}.btn:disabled{opacity:.5;cursor:wait}.message{margin-top:14px;padding:12px;border-radius:10px;font-size:13px}.error{background:#fff0ef;color:#7b2622}.success{background:#edf7ef;color:#285c36}.qr{display:block;width:min(260px,100%);margin:16px auto;background:#fff;padding:10px;border-radius:12px}.secret{display:block;padding:10px;background:#fff;border:1px solid var(--line);border-radius:8px;overflow-wrap:anywhere}.shell{display:grid;grid-template-columns:220px minmax(0,1fr);min-height:100vh}.sidebar{position:sticky;top:0;height:100vh;border-right:1px solid var(--line);padding:24px 18px;display:flex;flex-direction:column;background:#f7f8f5}.brand{font-weight:760;letter-spacing:-.02em;margin:3px 8px 30px}.nav{display:grid;gap:4px}.nav button{appearance:none;border:0;background:transparent;text-align:left;padding:10px 12px;border-radius:9px;color:#445148;font-weight:620}.nav button.active{background:#e7ede8;color:#173c2a}.side-foot{margin-top:auto;padding:14px 8px 4px;font-size:12px;color:var(--muted);line-height:1.5}.main{padding:42px clamp(24px,5vw,72px);max-width:1180px;width:100%}.view-head{display:flex;justify-content:space-between;gap:20px;align-items:flex-start;margin-bottom:32px}.view-head h1{margin-bottom:6px}.kicker{font-size:12px;color:var(--muted)}.section{margin:34px 0}.section-head{display:flex;justify-content:space-between;gap:16px;align-items:end;padding-bottom:10px;border-bottom:1px solid var(--line);margin-bottom:4px}.section-head h2{margin:0;font-size:17px}.row{padding:17px 2px;border-bottom:1px solid var(--line)}.row-top{display:flex;justify-content:space-between;gap:18px;align-items:flex-start}.row h3{margin:0 0 7px;font-size:15px}.row p{margin:5px 0;color:#435048;line-height:1.5;font-size:14px}.meta{display:flex;gap:10px;flex-wrap:wrap;margin-top:10px;font-size:12px;color:var(--muted)}.tag{display:inline-flex;align-items:center;padding:3px 7px;border-radius:99px;background:#edf0ed;border:1px solid #e0e5e0}.tag.attn{background:#fff1ed;color:#8a342b;border-color:#f0d1cb}.tag.ok{background:#eef6ef;color:#2e6038}.tag.warn{background:#fff7e8;color:#755019}.open{border:0;background:transparent;color:#214b34;font-weight:700;padding:0}.overview{display:flex;gap:22px;flex-wrap:wrap;padding:14px 0 3px}.overview strong{font-size:19px;display:block}.overview span{font-size:12px;color:var(--muted)}.empty{padding:30px 0;color:var(--muted)}.detail-grid{display:grid;grid-template-columns:160px 1fr;gap:12px 24px;padding:18px 0;border-top:1px solid var(--line)}.detail-grid dt{color:var(--muted);font-size:13px}.detail-grid dd{margin:0;line-height:1.5}.back{margin-bottom:24px}.source-link{color:#214b34;text-decoration:none;font-weight:650}.source-link:hover{text-decoration:underline}.spinner{padding:30px 0;color:var(--muted)}.system-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.system-card{background:#fafbf9;border:1px solid var(--line);border-radius:14px;padding:18px}.system-card h3{margin-bottom:9px}.system-card p{font-size:13px;color:var(--muted);margin:5px 0;line-height:1.5}.mobile-head{display:none}
@media(max-width:760px){.shell{display:block}.sidebar{display:none}.mobile-head{display:flex;position:sticky;top:0;z-index:5;background:rgba(247,248,245,.96);backdrop-filter:blur(8px);border-bottom:1px solid var(--line);padding:12px 14px;gap:7px;overflow-x:auto}.mobile-head button{border:0;background:transparent;padding:8px 10px;border-radius:8px;white-space:nowrap}.mobile-head button.active{background:#e7ede8}.main{padding:28px 20px}.view-head{margin-bottom:24px}.system-grid{grid-template-columns:1fr}.detail-grid{grid-template-columns:1fr;gap:4px}.detail-grid dt{margin-top:10px}}
</style></head><body><div id="root"><div class="auth-wrap"><div class="auth-card"><div class="eyebrow">Meterion Control Room</div><h1>Loading</h1><p class="intro">Preparing the private operating surface…</p></div></div></div>
<script type="module">
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const SUPABASE_URL=${JSON.stringify(SUPABASE_URL)};const supabase=createClient(SUPABASE_URL,${JSON.stringify(key)});const root=document.getElementById('root');let session=null;let currentView='today';let projectsCache=[];
function esc(v){return String(v??'').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#039;')}function fmtTime(v){if(!v)return 'Not verified';try{return new Intl.DateTimeFormat(undefined,{dateStyle:'medium',timeStyle:'short'}).format(new Date(v))}catch{return String(v)}}function first(v){return Array.isArray(v)?v[0]:v}function arr(v){return Array.isArray(v)?v:(v==null?[]:[v])}
async function post(body,token=session?.access_token){const headers={'content-type':'application/json'};if(token)headers.authorization='Bearer '+token;const r=await fetch(window.location.pathname,{method:'POST',headers,body:JSON.stringify(body),cache:'no-store'});let data={};try{data=await r.json()}catch{}if(!r.ok){const e=new Error(data.code||'request_failed');e.code=data.code;e.request_id=data.request_id;throw e}return data}async function read(api_action,extra={}){const r=await post({action:'read',api_action,...extra});return r.data}
function authFrame(inner,msg=''){root.innerHTML='<div class="auth-wrap"><main class="auth-card"><div class="eyebrow">Meterion Control Room</div><h1>Private operating surface</h1><p class="intro">Cross-project state, owner attention and resume-anywhere context. Access is allow-listed and requires TOTP MFA.</p><div class="panel">'+inner+'</div>'+msg+'</main></div>'}
function showLogin(){authFrame('<label for="email">Approved Meterion email</label><input id="email" type="email" autocomplete="email" placeholder="name@example.com"/><div class="buttons"><button id="send" class="btn primary">Send secure sign-in link</button></div><p class="muted">Only pre-approved Control Room emails can create or use an account.</p>');document.getElementById('send').onclick=async()=>{const b=document.getElementById('send');const email=document.getElementById('email').value.trim();if(!email)return;b.disabled=true;try{await post({action:'send_magic_link',email,redirect_to:window.location.origin+window.location.pathname},null);authFrame('<p>Check <strong>'+esc(email)+'</strong> and open the sign-in link in this browser.</p>','<div class="message success">The link is tied to this private Control Room login flow.</div>')}catch(e){authFrame('<p>Sign-in could not be started.</p>','<div class="message error">'+esc(e.code==='login_not_allowed'?'This email is not approved for Meterion Control Room.':'Could not send the sign-in link.')+'</div>')}}}
async function showMfaEnrollment(){const listed=await supabase.auth.mfa.listFactors();if(!listed.error){for(const f of listed.data.totp.filter(x=>x.status!=='verified'))await supabase.auth.mfa.unenroll({factorId:f.id})}const enrolled=await supabase.auth.mfa.enroll({factorType:'totp',friendlyName:'Meterion Control Room'});if(enrolled.error)throw enrolled.error;const f=enrolled.data;authFrame('<h2>Set up MFA</h2><p class="muted">Scan this QR code with your authenticator app, then enter the current code.</p><img class="qr" src="'+esc(f.totp.qr_code)+'" alt="TOTP QR code"/><label>Manual secret</label><code class="secret">'+esc(f.totp.secret||'')+'</code><label for="mfa">Authenticator code</label><input id="mfa" inputmode="numeric" autocomplete="one-time-code" maxlength="8"/><div class="buttons"><button id="verify" class="btn primary">Enable and verify MFA</button></div>');document.getElementById('verify').onclick=async()=>{const code=document.getElementById('mfa').value.trim();const c=await supabase.auth.mfa.challenge({factorId:f.id});if(c.error)return;const v=await supabase.auth.mfa.verify({factorId:f.id,challengeId:c.data.id,code});if(v.error)return;await supabase.auth.refreshSession();await boot()}}
async function showMfaChallenge(f){authFrame('<h2>Verify MFA</h2><p class="muted">Enter the current code from your authenticator app.</p><label for="mfa">Authenticator code</label><input id="mfa" inputmode="numeric" autocomplete="one-time-code" maxlength="8"/><div class="buttons"><button id="verify" class="btn primary">Verify</button></div>');document.getElementById('verify').onclick=async()=>{const code=document.getElementById('mfa').value.trim();const c=await supabase.auth.mfa.challenge({factorId:f.id});if(c.error)return;const v=await supabase.auth.mfa.verify({factorId:f.id,challengeId:c.data.id,code});if(v.error)return;await supabase.auth.refreshSession();await boot()}}
async function ensureMfa(){const aal=await supabase.auth.mfa.getAuthenticatorAssuranceLevel();if(aal.error)throw aal.error;if(aal.data.currentLevel==='aal2')return true;const factors=await supabase.auth.mfa.listFactors();if(factors.error)throw factors.error;const verified=factors.data.totp.find(f=>f.status==='verified');if(verified){await showMfaChallenge(verified);return false}await showMfaEnrollment();return false}
function shell(){root.innerHTML='<div class="mobile-head">'+navButtons()+'</div><div class="shell"><aside class="sidebar"><div class="brand">Meterion Control Room</div><nav class="nav">'+navButtons()+'</nav><div class="side-foot"><div id="identity">'+esc(session?.user?.email||'')+'</div><div>AAL2 · private</div><button id="signout" class="open" style="margin-top:8px">Sign out</button></div></aside><main id="main" class="main"></main></div>';document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>go(b.dataset.view));document.getElementById('signout').onclick=async()=>{await supabase.auth.signOut();location.reload()}}
function navButtons(){return ['today','projects','ai','system'].map(v=>'<button data-view="'+v+'" class="'+(v===currentView?'active':'')+'">'+({today:'Today',projects:'Projects',ai:'AI Company OS',system:'System'}[v])+'</button>').join('')}
function updateNav(){document.querySelectorAll('[data-view]').forEach(b=>b.classList.toggle('active',b.dataset.view===currentView))}
async function go(view){currentView=view;updateNav();const main=document.getElementById('main');main.innerHTML='<div class="spinner">Loading…</div>';try{if(view==='today')await renderToday();if(view==='projects')await renderProjects();if(view==='ai')await renderAi();if(view==='system')await renderSystem()}catch(e){main.innerHTML='<div class="view-head"><div><div class="eyebrow">Control Room</div><h1>Could not load this view</h1><p class="intro">The last verified Control Room state has not been replaced.</p></div></div><div class="message error">'+esc(e.code||e.message||'request_failed')+(e.request_id?' · '+esc(e.request_id):'')+'</div>'}}
function tag(text,cls=''){return '<span class="tag '+cls+'">'+esc(text)+'</span>'}
function projectRow(p){return '<div class="row"><div class="row-top"><div><h3>'+esc(p.name)+'</h3><p>'+esc(p.current_focus||p.goal||'No current focus recorded.')+'</p></div><button class="open" data-project="'+esc(p.project_key)+'">Open</button></div><div class="meta">'+tag(p.portfolio_class||p.projects_section||'UNCONFIRMED')+tag(p.autonomy_state||'state missing',p.autonomy_state==='owner_needed'?'attn':'')+tag(p.state_freshness||'missing',p.state_freshness==='fresh'?'ok':'warn')+(p.founder_attention_required?tag('Founder attention','attn'):'')+'</div></div>'}
function wireProjects(){document.querySelectorAll('[data-project]').forEach(b=>b.onclick=()=>renderProjectDetail(b.dataset.project))}
async function renderToday(){const rows=arr(await read('get_today'));const groups={needs_you:[],working_now:[],changed_materially:[]};rows.forEach(r=>{if(groups[r.today_section])groups[r.today_section].push(r)});let html='<div class="view-head"><div><div class="eyebrow">Today</div><h1>What needs attention</h1><p class="intro">Only intervention, active execution and material change.</p></div></div>';const specs=[['needs_you','Needs you'],['working_now','Working now'],['changed_materially','Changed materially']];let any=false;for(const [key,label] of specs){if(!groups[key].length)continue;any=true;html+='<section class="section"><div class="section-head"><h2>'+label+'</h2><span class="kicker">'+groups[key].length+'</span></div>'+groups[key].map(r=>'<div class="row"><div class="row-top"><div><h3>'+esc(r.name)+'</h3><p>'+esc(r.today_reason||r.current_focus||'')+'</p></div><button class="open" data-project="'+esc(r.project_key)+'">Open</button></div><div class="meta">'+(r.founder_gate&&r.founder_gate!=='none'?tag(r.founder_gate,'attn'):'')+tag(r.state_freshness||'missing',r.state_freshness==='fresh'?'ok':'warn')+'<span>'+esc(fmtTime(r.latest_event_at||r.verified_at))+'</span></div></div>').join('')+'</section>'}if(!any)html+='<div class="empty"><h2>Nothing needs your attention right now.</h2><p>Today is intentionally quiet when there are no meaningful exceptions or changes.</p></div>';document.getElementById('main').innerHTML=html;wireProjects()}
async function renderProjects(){const [overviewRaw,rowsRaw]=await Promise.all([read('get_projects_overview'),read('get_projects')]);const overview=first(overviewRaw)||{};const rows=arr(rowsRaw);projectsCache=rows;const active=rows.filter(r=>r.projects_section==='active_portfolio');const unclassified=rows.filter(r=>r.projects_section==='active_unclassified');const unconfirmed=rows.filter(r=>r.projects_section==='unconfirmed_identity');let html='<div class="view-head"><div><div class="eyebrow">Projects</div><h1>Portfolio truth</h1><p class="intro">Operational orientation without project-management overhead.</p></div></div><div class="overview"><div><strong>'+esc(overview.active_portfolio_count??active.length)+'</strong><span>confirmed active</span></div><div><strong>'+esc(overview.active_unclassified_count??unclassified.length)+'</strong><span>active unclassified</span></div><div><strong>'+esc(overview.unconfirmed_identity_count??unconfirmed.length)+'</strong><span>awaiting confirmation</span></div><div><strong>'+esc(overview.active_state_quality_exception_count??0)+'</strong><span>state exceptions</span></div></div>';for(const cls of ['CORE','EXPERIMENT','AUTOPILOT','MAINTENANCE','VAULT']){const items=active.filter(r=>r.portfolio_class===cls);if(!items.length)continue;html+='<section class="section"><div class="section-head"><h2>'+cls+'</h2><span class="kicker">'+items.length+'</span></div>'+items.map(projectRow).join('')+'</section>'}if(unclassified.length)html+='<section class="section"><div class="section-head"><h2>Active but unclassified</h2></div>'+unclassified.map(projectRow).join('')+'</section>';if(unconfirmed.length)html+='<details class="section"><summary>Needs lifecycle confirmation ('+unconfirmed.length+')</summary><div style="margin-top:12px">'+unconfirmed.map(projectRow).join('')+'</div></details>';document.getElementById('main').innerHTML=html;wireProjects()}
async function renderProjectDetail(key){const state=first(await read('get_project_state',{project_key:key}));const cached=projectsCache.find(p=>p.project_key===key);currentView='projects';updateNav();if(!state)return;const source=cached?.primary_connection_url?'<a class="source-link" target="_blank" rel="noreferrer" href="'+esc(cached.primary_connection_url)+'">Open source ↗</a>':esc(state.source_ref||'No source link');const pairs=[['Goal',state.goal],['Success definition',state.success_definition],['Phase',state.phase],['Current focus',state.current_focus],['Latest material result',state.last_material_result],['Next best action',state.next_best_action],['Blocker',state.blocker_summary||'None'],['Autonomy',String(state.autonomy_state||'')+(state.autonomy_reason?' — '+state.autonomy_reason:'')],['Founder attention',state.founder_attention_required?(state.founder_attention_reason||state.founder_gate):'None'],['Verification',(state.state_freshness||'missing')+' · '+fmtTime(state.verified_at)+' · '+(state.confidence||'')],['Source',source],['Canonical constraints',arr(state.canonical_constraints).join(' · ')||'None']];document.getElementById('main').innerHTML='<button class="open back" id="back">← Projects</button><div class="view-head"><div><div class="eyebrow">'+esc(state.portfolio_class||state.lifecycle_status||'Project')+'</div><h1>'+esc(state.name)+'</h1><p class="intro">Resume-anywhere orientation packet · state v'+esc(state.state_version??'—')+'</p></div></div><dl class="detail-grid">'+pairs.map(([a,b])=>'<dt>'+esc(a)+'</dt><dd>'+(a==='Source'?b:esc(b??'—'))+'</dd>').join('')+'</dl>';document.getElementById('back').onclick=()=>go('projects')}
async function renderAi(){const s=first(await read('get_project_state',{project_key:'ai-company-os'}));document.getElementById('main').innerHTML='<div class="view-head"><div><div class="eyebrow">AI Company OS</div><h1>'+esc(s?.phase||'AI Company OS')+'</h1><p class="intro">AI Company OS manages AI-native companies. Control Room tracks it only as one top-level Meterion system/project.</p></div></div>'+projectRow({...s,project_key:'ai-company-os',name:'AI Company OS',projects_section:'CORE'})+'<section class="section"><div class="section-head"><h2>Latest operating state</h2></div><div class="row"><h3>Material result</h3><p>'+esc(s?.last_material_result||'—')+'</p></div><div class="row"><h3>Next best action</h3><p>'+esc(s?.next_best_action||'—')+'</p></div></section>';wireProjects()}
async function renderSystem(){const [recRaw,attRaw,crRaw]=await Promise.all([read('get_state_reconciliation',{due_only:false}),read('get_owner_attention'),read('get_project_state',{project_key:'meterion-control-room'})]);const rec=arr(recRaw),att=arr(attRaw),cr=first(crRaw);const due=rec.filter(r=>r.refresh_due).length;const stale=rec.filter(r=>r.state_freshness==='stale'||r.state_freshness==='missing').length;document.getElementById('main').innerHTML='<div class="view-head"><div><div class="eyebrow">System</div><h1>Quiet diagnostics</h1><p class="intro">State quality, connections and material exceptions only.</p></div></div><div class="system-grid"><div class="system-card"><h3>State quality</h3><p><strong>'+due+'</strong> refresh due · <strong>'+stale+'</strong> stale/missing · '+rec.length+' tracked rows</p><p>Source reconciliation is advisory; canonical project identity remains Owner-controlled.</p></div><div class="system-card"><h3>Runtime</h3><p>Control Room API v2: live</p><p>Web gateway: authenticated / read-only</p><p>ChatGPT MCP: waiting on Business full-MCP tool discovery</p></div><div class="system-card"><h3>Owner attention</h3><p>'+att.length+' active founder gate'+(att.length===1?'':'s')+'.</p><p>'+esc(att[0]?.founder_attention_reason||'No owner action is currently required.')+'</p></div><div class="system-card"><h3>Control Room</h3><p>State v'+esc(cr?.state_version??'—')+' · '+esc(cr?.state_freshness||'unknown')+'</p><p>'+esc(cr?.current_focus||'')+'</p></div></div>'}
async function boot(){const got=await supabase.auth.getSession();session=got.data.session;if(!session){showLogin();return}history.replaceState({},'',window.location.pathname);try{await post({action:'session_status'})}catch{await supabase.auth.signOut();showLogin();return}const ready=await ensureMfa();if(!ready)return;const refreshed=await supabase.auth.getSession();session=refreshed.data.session;try{await post({action:'activate_first_operator'});shell();await go('today')}catch(e){authFrame('<h2>Access not activated</h2><p class="muted">Your account is authenticated, but it is not enrolled as an active Control Room operator.</p>','<div class="message error">'+esc(e.code||e.message)+'</div>')}}
boot().catch(e=>authFrame('<h2>Control Room could not initialize</h2>','<div class="message error">'+esc(e.message||String(e))+'</div>'));
</script></body></html>`;
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "POST") {
      try {
        return await handlePost(request);
      } catch {
        return json(500, { ok: false, code: "control_room_web_error" });
      }
    }
    if (request.method !== "GET") return new Response("Method not allowed", { status: 405 });
    return new Response(page(), {
      status: 200,
      headers: {
        "cache-control": "no-store",
        "content-type": "text/html; charset=utf-8",
        "content-security-policy": `default-src 'none'; script-src 'unsafe-inline' https://esm.sh; style-src 'unsafe-inline'; img-src data:; connect-src 'self' https://esm.sh ${SUPABASE_URL}; frame-ancestors 'none'; base-uri 'none'; form-action 'none'`,
        "referrer-policy": "no-referrer",
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
        "permissions-policy": "camera=(), microphone=(), geolocation=()",
      },
    });
  },
};
