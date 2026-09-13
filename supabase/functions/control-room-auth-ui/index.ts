import { createClient } from "npm:@supabase/supabase-js@2";

const PROJECT_REF = "cavvdvxicadgfftbziao";
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;
const AUTH_UI_PATH = "/functions/v1/control-room-auth-ui";

function publishableKey(): string {
  const named = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (named) {
    try {
      const parsed = JSON.parse(named) as Record<string, unknown>;
      if (typeof parsed.default === "string" && parsed.default.length > 0) {
        return parsed.default;
      }
    } catch {
      // Fall through.
    }
  }

  const fallback =
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY");
  if (!fallback) throw new Error("missing_supabase_publishable_key");
  return fallback;
}

function secretKey(): string {
  const named = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (named) {
    try {
      const parsed = JSON.parse(named) as Record<string, unknown>;
      if (typeof parsed.default === "string" && parsed.default.length > 0) {
        return parsed.default;
      }
    } catch {
      // Fall through.
    }
  }

  const fallback =
    Deno.env.get("SUPABASE_SECRET_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!fallback) throw new Error("missing_supabase_secret_key");
  return fallback;
}

const admin = createClient(SUPABASE_URL, secretKey(), {
  auth: { autoRefreshToken: false, persistSession: false },
});

const publicAuth = createClient(SUPABASE_URL, publishableKey(), {
  auth: { autoRefreshToken: false, persistSession: false },
});

function json(status: number, body: Record<string, unknown>): Response {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
      "content-type": "application/json; charset=utf-8",
      "x-content-type-options": "nosniff",
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
    if (!url.pathname.startsWith(AUTH_UI_PATH)) return null;
    return url.toString();
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

async function handlePost(request: Request): Promise<Response> {
  let body: Record<string, unknown>;
  try {
    const parsed = await request.json();
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return json(400, { ok: false, code: "invalid_request" });
    }
    body = parsed as Record<string, unknown>;
  } catch {
    return json(400, { ok: false, code: "invalid_json" });
  }

  if (body.action === "send_magic_link") {
    const email = normalizedEmail(body.email);
    const redirectTo = allowedReturnUrl(body.redirect_to);
    if (!email || !redirectTo) {
      return json(400, { ok: false, code: "invalid_request" });
    }

    const policy = await loginPolicy(email);
    if (!policy) {
      return json(403, { ok: false, code: "login_not_allowed" });
    }

    const { error } = await publicAuth.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: redirectTo,
        shouldCreateUser: true,
      },
    });

    if (error) {
      return json(400, { ok: false, code: "magic_link_failed" });
    }

    return json(200, { ok: true });
  }

  if (body.action === "session_eligibility") {
    const authorization = request.headers.get("authorization") ?? "";
    const match = authorization.match(/^Bearer\s+(.+)$/i);
    if (!match) return json(401, { ok: false, code: "missing_token" });

    const { data, error } = await admin.auth.getUser(match[1]);
    if (error || !data.user?.email) {
      return json(401, { ok: false, code: "invalid_session" });
    }

    const email = data.user.email.trim().toLowerCase();
    const policy = await loginPolicy(email);
    if (!policy) {
      return json(403, { ok: false, code: "login_not_allowed" });
    }

    return json(200, {
      ok: true,
      email,
      require_mfa: policy.require_mfa !== false,
    });
  }

  return json(400, { ok: false, code: "unknown_action" });
}

function page(): string {
  const key = publishableKey();
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Authorize Meterion Control Room</title>
  <meta name="robots" content="noindex,nofollow" />
  <style>
    :root { color-scheme: light; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #f4f5f3; color: #17201b; min-height: 100vh; display: grid; place-items: center; padding: 24px; }
    main { width: min(560px, 100%); background: #fff; border: 1px solid #dfe4df; border-radius: 20px; padding: 30px; box-shadow: 0 18px 50px rgba(20,35,25,.08); }
    .eyebrow { text-transform: uppercase; letter-spacing: .13em; font-size: 11px; font-weight: 700; color: #617067; }
    h1 { margin: 10px 0 10px; font-size: 28px; letter-spacing: -.03em; }
    p { line-height: 1.55; color: #4c5a52; }
    .panel { margin-top: 22px; padding: 18px; background: #f7f8f6; border: 1px solid #e3e7e3; border-radius: 14px; }
    label { display: block; font-size: 13px; font-weight: 650; margin: 14px 0 7px; }
    input { width: 100%; border: 1px solid #cbd3cd; border-radius: 10px; padding: 12px 13px; font: inherit; background: #fff; }
    .buttons { display: flex; gap: 10px; margin-top: 18px; flex-wrap: wrap; }
    button { border: 0; border-radius: 10px; padding: 11px 15px; font: inherit; font-weight: 650; cursor: pointer; }
    button.primary { background: #173c2a; color: #fff; }
    button.secondary { background: #e9eeea; color: #223229; }
    button:disabled { opacity: .5; cursor: wait; }
    .muted { color: #758078; font-size: 13px; }
    .error { margin-top: 14px; padding: 12px; border-radius: 10px; background: #fff0ef; color: #7b2622; font-size: 13px; white-space: pre-wrap; }
    .success { margin-top: 14px; padding: 12px; border-radius: 10px; background: #edf7ef; color: #285c36; font-size: 13px; }
    dl { display: grid; grid-template-columns: 110px 1fr; gap: 9px 14px; margin: 0; font-size: 14px; }
    dt { color: #758078; }
    dd { margin: 0; overflow-wrap: anywhere; }
    ul { margin-bottom: 0; }
    .qr { display: block; width: min(260px, 100%); margin: 16px auto; background: #fff; padding: 10px; border-radius: 12px; }
    code.secret { display: block; padding: 10px; background: #fff; border: 1px solid #dfe4df; border-radius: 8px; overflow-wrap: anywhere; }
  </style>
</head>
<body>
<main>
  <div class="eyebrow">Meterion Control Room</div>
  <h1 id="title">Authorize access</h1>
  <p id="intro">Secure sign-in, MFA and consent for the private Meterion Control Room MCP connection.</p>
  <div id="app" class="panel"><p class="muted">Loading authorization request…</p></div>
  <div id="message"></div>
</main>
<script type="module">
  import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

  const supabase = createClient(${JSON.stringify(SUPABASE_URL)}, ${JSON.stringify(key)});
  const app = document.getElementById('app');
  const message = document.getElementById('message');
  const params = new URLSearchParams(window.location.search);
  const authorizationId = params.get('authorization_id');

  function esc(value) {
    return String(value ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  function setError(text) {
    message.innerHTML = '<div class="error">' + esc(text) + '</div>';
  }

  function setSuccess(text) {
    message.innerHTML = '<div class="success">' + esc(text) + '</div>';
  }

  function consentReturnUrl() {
    return window.location.href;
  }

  async function api(action, body = {}, token = null) {
    const headers = { 'content-type': 'application/json' };
    if (token) headers.authorization = 'Bearer ' + token;
    const response = await fetch(window.location.href, {
      method: 'POST',
      headers,
      body: JSON.stringify({ action, ...body }),
      cache: 'no-store',
    });
    let data = {};
    try { data = await response.json(); } catch {}
    if (!response.ok) {
      const error = new Error(data.code || 'request_failed');
      error.code = data.code;
      throw error;
    }
    return data;
  }

  async function showLogin() {
    app.innerHTML =
      '<label for="email">Approved Meterion sign-in email</label>' +
      '<input id="email" type="email" autocomplete="email" placeholder="name@example.com" />' +
      '<div class="buttons"><button id="send" class="primary">Send secure sign-in link</button></div>' +
      '<p class="muted">Only pre-approved Control Room emails can start sign-in. The authorization request remains attached to the magic link.</p>';

    document.getElementById('send').addEventListener('click', async () => {
      message.innerHTML = '';
      const email = document.getElementById('email').value.trim();
      if (!email) return setError('Enter your sign-in email.');
      const button = document.getElementById('send');
      button.disabled = true;
      try {
        await api('send_magic_link', { email, redirect_to: consentReturnUrl() });
        setSuccess('Sign-in link sent. Open it in this browser to continue authorization.');
      } catch (error) {
        if (error.code === 'login_not_allowed') {
          setError('This email is not approved for Meterion Control Room.');
        } else {
          setError('Could not send the secure sign-in link.');
        }
      } finally {
        button.disabled = false;
      }
    });
  }

  async function verifyExistingMfa() {
    const factors = await supabase.auth.mfa.listFactors();
    if (factors.error) throw factors.error;
    const factor = factors.data.totp.find((f) => f.status === 'verified');
    if (!factor) return showMfaEnrollment();

    app.innerHTML =
      '<h2>Verify second factor</h2>' +
      '<p class="muted">Enter the current code from your authenticator app.</p>' +
      '<label for="mfa-code">Authenticator code</label>' +
      '<input id="mfa-code" inputmode="numeric" autocomplete="one-time-code" maxlength="8" />' +
      '<div class="buttons"><button id="mfa-verify" class="primary">Verify MFA</button></div>';

    document.getElementById('mfa-verify').addEventListener('click', async () => {
      message.innerHTML = '';
      const code = document.getElementById('mfa-code').value.trim();
      if (!code) return setError('Enter the authenticator code.');
      const challenge = await supabase.auth.mfa.challenge({ factorId: factor.id });
      if (challenge.error) return setError(challenge.error.message);
      const verify = await supabase.auth.mfa.verify({
        factorId: factor.id,
        challengeId: challenge.data.id,
        code,
      });
      if (verify.error) return setError(verify.error.message);
      setSuccess('MFA verified.');
      await loadConsent();
    });
  }

  async function showMfaEnrollment() {
    const listed = await supabase.auth.mfa.listFactors();
    if (!listed.error) {
      for (const factor of listed.data.totp.filter((f) => f.status !== 'verified')) {
        await supabase.auth.mfa.unenroll({ factorId: factor.id });
      }
    }

    const enrolled = await supabase.auth.mfa.enroll({
      factorType: 'totp',
      friendlyName: 'Meterion Control Room',
    });
    if (enrolled.error) throw enrolled.error;

    const factor = enrolled.data;
    app.innerHTML =
      '<h2>Set up MFA</h2>' +
      '<p class="muted">Control Room requires TOTP MFA. Scan this QR code with 1Password, Google Authenticator, Authy or another authenticator app.</p>' +
      '<img class="qr" alt="TOTP QR code" src="' + esc(factor.totp.qr_code) + '" />' +
      '<label>Manual secret</label><code class="secret">' + esc(factor.totp.secret || '') + '</code>' +
      '<label for="mfa-code">Authenticator code</label>' +
      '<input id="mfa-code" inputmode="numeric" autocomplete="one-time-code" maxlength="8" />' +
      '<div class="buttons"><button id="mfa-enable" class="primary">Enable and verify MFA</button></div>';

    document.getElementById('mfa-enable').addEventListener('click', async () => {
      message.innerHTML = '';
      const code = document.getElementById('mfa-code').value.trim();
      if (!code) return setError('Enter the authenticator code.');
      const challenge = await supabase.auth.mfa.challenge({ factorId: factor.id });
      if (challenge.error) return setError(challenge.error.message);
      const verify = await supabase.auth.mfa.verify({
        factorId: factor.id,
        challengeId: challenge.data.id,
        code,
      });
      if (verify.error) return setError(verify.error.message);
      await supabase.auth.refreshSession();
      setSuccess('MFA enabled and verified.');
      await loadConsent();
    });
  }

  async function enforceMfa() {
    const aal = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
    if (aal.error) throw aal.error;
    if (aal.data.currentLevel === 'aal2') return true;
    if (aal.data.nextLevel === 'aal2') {
      await verifyExistingMfa();
      return false;
    }
    await showMfaEnrollment();
    return false;
  }

  async function loadConsent() {
    message.innerHTML = '';
    if (!authorizationId) {
      app.innerHTML = '<p>Missing authorization request.</p>';
      setError('Open this page through the ChatGPT OAuth authorization flow.');
      return;
    }

    const { data: sessionData } = await supabase.auth.getSession();
    const session = sessionData.session;
    if (!session) {
      await showLogin();
      return;
    }

    try {
      const eligibility = await api('session_eligibility', {}, session.access_token);
      if (eligibility.require_mfa !== false) {
        const ready = await enforceMfa();
        if (!ready) return;
      }
    } catch (error) {
      await supabase.auth.signOut();
      app.innerHTML = '<p>Access denied.</p>';
      setError('This account is not approved for Meterion Control Room.');
      return;
    }

    const { data, error } = await supabase.auth.oauth.getAuthorizationDetails(authorizationId);
    if (error || !data) {
      app.innerHTML = '<p>Authorization request could not be loaded.</p>';
      setError(error?.message ?? 'Invalid or expired authorization request.');
      return;
    }

    if (!('authorization_id' in data)) {
      window.location.replace(data.redirect_url);
      return;
    }

    const clientName = data.client?.name ?? 'ChatGPT';
    const scopes = String(data.scope ?? '').trim().split(/\\s+/).filter(Boolean);
    document.getElementById('title').textContent = 'Authorize ' + clientName;
    document.getElementById('intro').textContent = 'This grants an MFA-verified, allow-listed Meterion operator access to the bounded Control Room MCP tools.';

    app.innerHTML =
      '<dl>' +
        '<dt>Client</dt><dd>' + esc(clientName) + '</dd>' +
        '<dt>Redirect</dt><dd>' + esc(data.redirect_uri ?? '') + '</dd>' +
        '<dt>Scopes</dt><dd>' + (scopes.length ? '<ul>' + scopes.map(s => '<li>' + esc(s) + '</li>').join('') + '</ul>' : 'Default') + '</dd>' +
        '<dt>Security</dt><dd>Email allow-list + TOTP MFA + OAuth client binding</dd>' +
      '</dl>' +
      '<div class="buttons">' +
        '<button id="approve" class="primary">Approve access</button>' +
        '<button id="deny" class="secondary">Deny</button>' +
        '<button id="signout" class="secondary">Sign out</button>' +
      '</div>' +
      '<p class="muted">Approval still does not bypass Control Room authorization. The MCP server separately checks the operator allow-list, approved OAuth client and MFA assurance level.</p>';

    document.getElementById('approve').addEventListener('click', async () => {
      message.innerHTML = '';
      const { data: approved, error: approveError } = await supabase.auth.oauth.approveAuthorization(authorizationId);
      if (approveError) return setError(approveError.message);
      window.location.replace(approved.redirect_url);
    });

    document.getElementById('deny').addEventListener('click', async () => {
      message.innerHTML = '';
      const { data: denied, error: denyError } = await supabase.auth.oauth.denyAuthorization(authorizationId);
      if (denyError) return setError(denyError.message);
      window.location.replace(denied.redirect_url);
    });

    document.getElementById('signout').addEventListener('click', async () => {
      await supabase.auth.signOut();
      window.location.reload();
    });
  }

  loadConsent().catch((error) => {
    app.innerHTML = '<p>Authorization UI failed to initialize.</p>';
    setError(error?.message ?? String(error));
  });
</script>
</body>
</html>`;
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "POST") {
      try {
        return await handlePost(request);
      } catch {
        return json(500, { ok: false, code: "authorization_service_error" });
      }
    }

    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    return new Response(page(), {
      status: 200,
      headers: {
        "cache-control": "no-store",
        "content-type": "text/html; charset=utf-8",
        "content-security-policy": "default-src 'none'; script-src 'unsafe-inline' https://esm.sh; style-src 'unsafe-inline'; img-src data:; connect-src 'self' https://esm.sh https://cavvdvxicadgfftbziao.supabase.co; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
        "referrer-policy": "no-referrer",
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
      },
    });
  },
};
