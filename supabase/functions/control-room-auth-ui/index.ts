const PROJECT_REF = "cavvdvxicadgfftbziao";
const SUPABASE_URL = `https://${PROJECT_REF}.supabase.co`;

function publishableKey(): string {
  const named = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (named) {
    try {
      const parsed = JSON.parse(named) as Record<string, unknown>;
      if (typeof parsed.default === "string" && parsed.default.length > 0) {
        return parsed.default;
      }
    } catch {
      // Fall through to the single-key environment variable.
    }
  }

  const fallback =
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? Deno.env.get("SUPABASE_ANON_KEY");
  if (!fallback) throw new Error("missing_supabase_publishable_key");
  return fallback;
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
    label { display: block; font-size: 13px; font-weight: 650; margin-bottom: 7px; }
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
  </style>
</head>
<body>
<main>
  <div class="eyebrow">Meterion Control Room</div>
  <h1 id="title">Authorize access</h1>
  <p id="intro">Secure sign-in and consent for the private Meterion Control Room MCP connection.</p>
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

  async function showLogin() {
    app.innerHTML = \
      '<label for="email">Meterion sign-in email</label>' +
      '<input id="email" type="email" autocomplete="email" placeholder="name@example.com" />' +
      '<div class="buttons"><button id="send" class="primary">Send secure sign-in link</button></div>' +
      '<p class="muted">The authorization request stays attached to the sign-in link. After signing in, return here to review access.</p>';

    document.getElementById('send').addEventListener('click', async () => {
      message.innerHTML = '';
      const email = document.getElementById('email').value.trim();
      if (!email) return setError('Enter your sign-in email.');
      const button = document.getElementById('send');
      button.disabled = true;
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: { emailRedirectTo: consentReturnUrl() },
      });
      button.disabled = false;
      if (error) return setError(error.message);
      setSuccess('Sign-in link sent. Open it in this browser to continue authorization.');
    });
  }

  async function loadConsent() {
    if (!authorizationId) {
      app.innerHTML = '<p>Missing authorization request.</p>';
      setError('Open this page through the ChatGPT OAuth authorization flow.');
      return;
    }

    const { data: sessionData } = await supabase.auth.getSession();
    if (!sessionData.session) {
      await showLogin();
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
    document.getElementById('intro').textContent = 'This grants the authenticated Meterion operator access to the bounded Control Room MCP tools.';

    app.innerHTML =
      '<dl>' +
        '<dt>Client</dt><dd>' + esc(clientName) + '</dd>' +
        '<dt>Redirect</dt><dd>' + esc(data.redirect_uri ?? '') + '</dd>' +
        '<dt>Scopes</dt><dd>' + (scopes.length ? '<ul>' + scopes.map(s => '<li>' + esc(s) + '</li>').join('') + '</ul>' : 'Default') + '</dd>' +
      '</dl>' +
      '<div class="buttons">' +
        '<button id="approve" class="primary">Approve access</button>' +
        '<button id="deny" class="secondary">Deny</button>' +
        '<button id="signout" class="secondary">Sign out</button>' +
      '</div>' +
      '<p class="muted">Approval does not bypass Control Room permissions. The MCP server separately checks the private operator allow-list.</p>';

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
  fetch(request: Request): Response {
    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    return new Response(page(), {
      status: 200,
      headers: {
        "cache-control": "no-store",
        "content-type": "text/html; charset=utf-8",
        "referrer-policy": "no-referrer",
        "x-content-type-options": "nosniff",
        "x-frame-options": "DENY",
      },
    });
  },
};
