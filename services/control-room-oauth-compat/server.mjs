import http from "node:http";
import { Readable } from "node:stream";

const PORT = Number(process.env.PORT || 10000);
const PUBLIC_ORIGIN = "https://meterion-control-room-oauth-compat.onrender.com";
const SUPABASE_ORIGIN = "https://cavvdvxicadgfftbziao.supabase.co";
const SUPABASE_AUTH = `${SUPABASE_ORIGIN}/auth/v1`;
const SUPABASE_MCP = `${SUPABASE_ORIGIN}/functions/v1/control-room-mcp-v1`;
const PUBLIC_HOST = new URL(PUBLIC_ORIGIN).host;

const unauthenticatedBuckets = new Map();

function externalBase() {
  return PUBLIC_ORIGIN;
}

function securityHeaders() {
  return {
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "x-frame-options": "DENY",
  };
}

function json(res, status, body, extraHeaders = {}) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(payload),
    "cache-control": "no-store",
    ...securityHeaders(),
    ...extraHeaders,
  });
  res.end(payload);
}

function oauthMetadata(base) {
  return {
    issuer: base,
    authorization_endpoint: `${base}/oauth/authorize`,
    token_endpoint: `${base}/oauth/token`,
    scopes_supported: ["email"],
    response_types_supported: ["code"],
    response_modes_supported: ["query"],
    grant_types_supported: ["authorization_code", "refresh_token"],
    token_endpoint_auth_methods_supported: ["none"],
    code_challenge_methods_supported: ["S256"],
  };
}

function resourceMetadata(base) {
  return {
    resource: `${base}/mcp`,
    authorization_servers: [base],
    scopes_supported: ["email"],
    bearer_methods_supported: ["header"],
    resource_name: "Meterion Control Room",
  };
}

function redirectTo(res, target) {
  res.writeHead(302, {
    location: target,
    "cache-control": "no-store",
    ...securityHeaders(),
  });
  res.end();
}

async function readBody(req) {
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    total += chunk.length;
    if (total > 128 * 1024) throw new Error("request_too_large");
    chunks.push(chunk);
  }
  return chunks.length ? Buffer.concat(chunks) : undefined;
}

function passthroughHeaders(sourceHeaders) {
  const headers = { ...securityHeaders() };
  const allow = [
    "content-type",
    "cache-control",
    "www-authenticate",
    "mcp-session-id",
    "retry-after",
  ];
  for (const key of allow) {
    const value = sourceHeaders.get(key);
    if (value) headers[key] = value;
  }
  return headers;
}

function clientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded) {
    return forwarded.split(",")[0].trim();
  }
  return req.socket.remoteAddress || "unknown";
}

function allowUnauthenticatedProbe(req) {
  const now = Date.now();
  const windowMs = 60_000;
  const max = 90;
  const key = clientIp(req);
  const existing = unauthenticatedBuckets.get(key);
  if (!existing || now - existing.startedAt >= windowMs) {
    unauthenticatedBuckets.set(key, { startedAt: now, count: 1 });
    return true;
  }
  existing.count += 1;
  return existing.count <= max;
}

async function proxy(req, res, target, { interceptUnauthorized = false } = {}) {
  const headers = new Headers();
  for (const key of ["authorization", "content-type", "accept", "mcp-session-id", "last-event-id"]) {
    const value = req.headers[key];
    if (value) headers.set(key, Array.isArray(value) ? value.join(",") : value);
  }

  const body = req.method === "GET" || req.method === "HEAD" ? undefined : await readBody(req);
  const upstream = await fetch(target, {
    method: req.method,
    headers,
    body,
    redirect: "manual",
  });

  if (interceptUnauthorized && upstream.status === 401) {
    const base = externalBase();
    res.writeHead(401, {
      "content-type": "application/json; charset=utf-8",
      "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource/mcp"`,
      "cache-control": "no-store",
      ...securityHeaders(),
    });
    res.end(JSON.stringify({ error: "unauthorized" }));
    return;
  }

  const headersOut = passthroughHeaders(upstream.headers);
  res.writeHead(upstream.status, headersOut);
  if (!upstream.body) {
    res.end();
    return;
  }

  Readable.fromWeb(upstream.body).pipe(res);
}

const server = http.createServer(async (req, res) => {
  try {
    const base = externalBase();
    const url = new URL(req.url || "/", base);
    const forwardedHost = (req.headers["x-forwarded-host"] || req.headers.host || "")
      .toString()
      .split(",")[0]
      .trim()
      .toLowerCase();

    if (forwardedHost && forwardedHost !== PUBLIC_HOST) {
      return json(res, 421, { error: "misdirected_request" });
    }

    if (req.method === "GET" && url.pathname === "/healthz") {
      return json(res, 200, { ok: true, service: "meterion-control-room-oauth-compat" });
    }

    if (
      req.method === "GET" &&
      (url.pathname === "/.well-known/oauth-authorization-server" ||
        url.pathname === "/.well-known/openid-configuration")
    ) {
      return json(res, 200, oauthMetadata(base), {
        "cache-control": "public, max-age=300",
      });
    }

    if (
      req.method === "GET" &&
      (url.pathname === "/.well-known/oauth-protected-resource" ||
        url.pathname === "/.well-known/oauth-protected-resource/mcp")
    ) {
      return json(res, 200, resourceMetadata(base), {
        "cache-control": "public, max-age=300",
      });
    }

    if (url.pathname === "/oauth/authorize" && req.method === "GET") {
      const target = new URL(`${SUPABASE_AUTH}/oauth/authorize`);
      target.search = url.search;
      return redirectTo(res, target.toString());
    }

    if (url.pathname === "/oauth/token" && req.method === "POST") {
      return proxy(req, res, `${SUPABASE_AUTH}/oauth/token`);
    }

    // Fail closed: this compatibility layer deliberately does not expose dynamic
    // OAuth client registration. Control Room accepts only explicitly approved
    // client IDs registered in Supabase and allow-listed by the MCP resource.
    if (url.pathname === "/oauth/register") {
      return json(res, 404, { error: "dynamic_registration_disabled" });
    }

    if (url.pathname === "/mcp") {
      if (!req.headers.authorization) {
        if (!allowUnauthenticatedProbe(req)) {
          return json(res, 429, { error: "rate_limited" }, { "retry-after": "60" });
        }
        res.writeHead(401, {
          "content-type": "application/json; charset=utf-8",
          "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource/mcp"`,
          "cache-control": "no-store",
          ...securityHeaders(),
        });
        res.end(JSON.stringify({ error: "unauthorized" }));
        return;
      }
      return proxy(req, res, SUPABASE_MCP, { interceptUnauthorized: true });
    }

    if (req.method === "OPTIONS") {
      res.writeHead(204, {
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "GET,POST,OPTIONS",
        "access-control-allow-headers": "Authorization,Content-Type,Accept,Mcp-Session-Id,Last-Event-Id",
        ...securityHeaders(),
      });
      res.end();
      return;
    }

    json(res, 404, { error: "not_found" });
  } catch (error) {
    const code = error instanceof Error && error.message === "request_too_large"
      ? "request_too_large"
      : "compatibility_proxy_error";
    json(res, code === "request_too_large" ? 413 : 502, { error: code });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Meterion Control Room OAuth compatibility service listening on ${PORT}`);
});
