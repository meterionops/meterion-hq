import http from "node:http";
import { Readable } from "node:stream";

const PORT = Number(process.env.PORT || 10000);
const SUPABASE_ORIGIN = "https://cavvdvxicadgfftbziao.supabase.co";
const SUPABASE_AUTH = `${SUPABASE_ORIGIN}/auth/v1`;
const SUPABASE_MCP = `${SUPABASE_ORIGIN}/functions/v1/control-room-mcp-v1`;

function externalBase(req) {
  const proto = (req.headers["x-forwarded-proto"] || "https").toString().split(",")[0].trim();
  const host = req.headers["x-forwarded-host"] || req.headers.host;
  return `${proto}://${host}`;
}

function json(res, status, body, extraHeaders = {}) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(payload),
    "cache-control": "no-store",
    ...extraHeaders,
  });
  res.end(payload);
}

function oauthMetadata(base) {
  return {
    issuer: base,
    authorization_endpoint: `${base}/oauth/authorize`,
    token_endpoint: `${base}/oauth/token`,
    registration_endpoint: `${base}/oauth/register`,
    scopes_supported: ["email"],
    response_types_supported: ["code"],
    response_modes_supported: ["query"],
    grant_types_supported: ["authorization_code", "refresh_token"],
    token_endpoint_auth_methods_supported: ["none", "client_secret_basic", "client_secret_post"],
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
  res.writeHead(302, { location: target, "cache-control": "no-store" });
  res.end();
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return chunks.length ? Buffer.concat(chunks) : undefined;
}

function passthroughHeaders(sourceHeaders) {
  const headers = {};
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
    const base = externalBase(req);
    res.writeHead(401, {
      "content-type": "application/json; charset=utf-8",
      "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource/mcp"`,
      "cache-control": "no-store",
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
    const base = externalBase(req);
    const url = new URL(req.url || "/", base);

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

    if (url.pathname === "/oauth/register" && req.method === "POST") {
      return proxy(req, res, `${SUPABASE_AUTH}/oauth/clients/register`);
    }

    if (url.pathname === "/mcp") {
      if (!req.headers.authorization) {
        res.writeHead(401, {
          "content-type": "application/json; charset=utf-8",
          "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource/mcp"`,
          "cache-control": "no-store",
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
      });
      res.end();
      return;
    }

    json(res, 404, { error: "not_found" });
  } catch (error) {
    console.error(error);
    json(res, 502, { error: "compatibility_proxy_error" });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Meterion Control Room OAuth compatibility service listening on ${PORT}`);
});
