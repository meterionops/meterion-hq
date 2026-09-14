import http from "node:http";
import { Readable } from "node:stream";

const PORT = Number(process.env.PORT || 10000);
const PUBLIC_ORIGIN = "https://meterion-control-room-oauth-compat.onrender.com";
const SUPABASE_ORIGIN = "https://cavvdvxicadgfftbziao.supabase.co";
const SUPABASE_AUTH = `${SUPABASE_ORIGIN}/auth/v1`;
const SUPABASE_MCP = `${SUPABASE_ORIGIN}/functions/v1/control-room-mcp-v1`;
const PUBLIC_HOST = new URL(PUBLIC_ORIGIN).host;
const unauthenticatedBuckets = new Map();

const readOnlyAnnotations = {
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false,
};
const writeAnnotations = {
  readOnlyHint: false,
  destructiveHint: false,
  idempotentHint: false,
  openWorldHint: false,
};

const TOOLS = [
  {
    name: "get_project_state",
    title: "Get project state",
    description: "Read the current canonical Control Room state for one Meterion project before continuing substantial work.",
    inputSchema: {
      type: "object",
      properties: { project_key: { type: "string", pattern: "^[a-z0-9][a-z0-9-]*$" } },
      required: ["project_key"],
      additionalProperties: false,
    },
    annotations: readOnlyAnnotations,
  },
  {
    name: "list_projects",
    title: "List Meterion projects",
    description: "List Control Room project summaries, optionally filtered by portfolio class or lifecycle status.",
    inputSchema: {
      type: "object",
      properties: {
        portfolio_class: { type: "string", enum: ["CORE", "EXPERIMENT", "AUTOPILOT", "MAINTENANCE", "VAULT", "SYSTEM", "UNCONFIRMED"] },
        lifecycle_status: { type: "string", enum: ["active", "paused", "completed", "archived", "unconfirmed"] },
      },
      additionalProperties: false,
    },
    annotations: readOnlyAnnotations,
  },
  {
    name: "get_today",
    title: "Get Meterion Today",
    description: "Read the canonical Today priority surface. Use this first when the user asks what needs attention or what to work on now.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
    annotations: readOnlyAnnotations,
  },
  {
    name: "get_owner_attention",
    title: "Get owner attention",
    description: "Return only active project states that currently require an explicit Founder action or decision.",
    inputSchema: { type: "object", properties: {}, additionalProperties: false },
    annotations: readOnlyAnnotations,
  },
  {
    name: "update_project_state",
    title: "Update project state",
    description: "Append a new operational state version after a meaningful work batch. Never use this to change Owner-controlled goal, portfolio class, lifecycle or locked constraints.",
    inputSchema: {
      type: "object",
      properties: {
        project_key: { type: "string", pattern: "^[a-z0-9][a-z0-9-]*$" },
        expected_version: { type: "integer", minimum: 0 },
        state: {
          type: "object",
          properties: {
            phase: { type: "string", maxLength: 500 },
            current_focus: { type: "string", maxLength: 4000 },
            last_material_result: { type: "string", maxLength: 4000 },
            next_best_action: { type: "string", maxLength: 4000 },
            blocked: { type: "boolean" },
            blocker_summary: { type: ["string", "null"], maxLength: 4000 },
            autonomy_state: { type: "string", enum: ["working", "can_continue", "waiting", "owner_needed", "inactive"] },
            autonomy_reason: { type: ["string", "null"], maxLength: 4000 },
            founder_attention_required: { type: "boolean" },
            founder_gate: { type: "string", enum: ["none", "strategic_decision", "credential", "legal_commercial", "external_communication", "contract", "customer_data", "production_mutation", "spend", "live_money"] },
            founder_attention_reason: { type: ["string", "null"], maxLength: 4000 },
            founder_attention_unlocks: { type: ["string", "null"], maxLength: 4000 },
            confidence: { type: "string", enum: ["low", "medium", "high"] },
            verified_at: { type: "string", maxLength: 100 },
            source_type: { type: "string", maxLength: 100 },
            source_ref: { type: ["string", "null"], maxLength: 1000 },
          },
          additionalProperties: false,
        },
      },
      required: ["project_key", "expected_version", "state"],
      additionalProperties: false,
    },
    annotations: writeAnnotations,
  },
  {
    name: "append_project_event",
    title: "Append material project event",
    description: "Append a material project event only when it changes future orientation. Do not log routine prompts, API calls or granular work rows.",
    inputSchema: {
      type: "object",
      properties: {
        project_key: { type: "string", pattern: "^[a-z0-9][a-z0-9-]*$" },
        event: {
          type: "object",
          properties: {
            event_type: { type: "string", minLength: 1, maxLength: 100 },
            summary: { type: "string", minLength: 1, maxLength: 4000 },
            importance: { type: "string", enum: ["low", "normal", "high", "critical"] },
            occurred_at: { type: "string", maxLength: 100 },
            source_type: { type: "string", maxLength: 100 },
            source_ref: { type: ["string", "null"], maxLength: 1000 },
            metadata: { type: "object", additionalProperties: true },
          },
          required: ["summary"],
          additionalProperties: false,
        },
      },
      required: ["project_key", "event"],
      additionalProperties: false,
    },
    annotations: writeAnnotations,
  },
];

function externalBase() { return PUBLIC_ORIGIN; }
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
  res.writeHead(302, { location: target, "cache-control": "no-store", ...securityHeaders() });
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
  for (const key of ["content-type", "cache-control", "www-authenticate", "mcp-session-id", "retry-after"]) {
    const value = sourceHeaders.get(key);
    if (value) headers[key] = value;
  }
  return headers;
}
function clientIp(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded) return forwarded.split(",")[0].trim();
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
async function proxy(req, res, target, { interceptUnauthorized = false, bodyOverride } = {}) {
  const headers = new Headers();
  for (const key of ["authorization", "content-type", "accept", "mcp-session-id", "last-event-id"]) {
    const value = req.headers[key];
    if (value) headers.set(key, Array.isArray(value) ? value.join(",") : value);
  }
  const body = bodyOverride !== undefined
    ? bodyOverride
    : (req.method === "GET" || req.method === "HEAD" ? undefined : await readBody(req));
  const upstream = await fetch(target, { method: req.method, headers, body, redirect: "manual" });
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
  res.writeHead(upstream.status, passthroughHeaders(upstream.headers));
  if (!upstream.body) return res.end();
  Readable.fromWeb(upstream.body).pipe(res);
}
function rpcResult(res, id, result) {
  return json(res, 200, { jsonrpc: "2.0", id, result });
}
function publicDiscoveryResponse(res, body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return false;
  const method = body.method;
  const id = Object.prototype.hasOwnProperty.call(body, "id") ? body.id : null;
  if (method === "initialize") {
    const requested = body.params && typeof body.params.protocolVersion === "string"
      ? body.params.protocolVersion
      : "2025-06-18";
    rpcResult(res, id, {
      protocolVersion: requested,
      capabilities: { tools: { listChanged: false } },
      serverInfo: { name: "Meterion Control Room", version: "1.1.1" },
    });
    return true;
  }
  if (method === "tools/list") {
    rpcResult(res, id, { tools: TOOLS });
    return true;
  }
  if (method === "ping") {
    rpcResult(res, id, {});
    return true;
  }
  if (method === "notifications/initialized") {
    res.writeHead(202, { "cache-control": "no-store", ...securityHeaders() });
    res.end();
    return true;
  }
  return false;
}
function unauthorized(res, base) {
  res.writeHead(401, {
    "content-type": "application/json; charset=utf-8",
    "www-authenticate": `Bearer resource_metadata="${base}/.well-known/oauth-protected-resource/mcp"`,
    "cache-control": "no-store",
    ...securityHeaders(),
  });
  res.end(JSON.stringify({ error: "unauthorized" }));
}

const server = http.createServer(async (req, res) => {
  try {
    const base = externalBase();
    const url = new URL(req.url || "/", base);
    const forwardedHost = (req.headers["x-forwarded-host"] || req.headers.host || "")
      .toString().split(",")[0].trim().toLowerCase();
    if (forwardedHost && forwardedHost !== PUBLIC_HOST) return json(res, 421, { error: "misdirected_request" });

    if (req.method === "GET" && url.pathname === "/healthz") {
      return json(res, 200, { ok: true, service: "meterion-control-room-oauth-compat", public_tool_discovery: true });
    }
    if (req.method === "GET" && (url.pathname === "/.well-known/oauth-authorization-server" || url.pathname === "/.well-known/openid-configuration")) {
      return json(res, 200, oauthMetadata(base), { "cache-control": "public, max-age=300" });
    }
    if (req.method === "GET" && (url.pathname === "/.well-known/oauth-protected-resource" || url.pathname === "/.well-known/oauth-protected-resource/mcp")) {
      return json(res, 200, resourceMetadata(base), { "cache-control": "public, max-age=300" });
    }
    if (url.pathname === "/oauth/authorize" && req.method === "GET") {
      const target = new URL(`${SUPABASE_AUTH}/oauth/authorize`);
      target.search = url.search;
      return redirectTo(res, target.toString());
    }
    if (url.pathname === "/oauth/token" && req.method === "POST") return proxy(req, res, `${SUPABASE_AUTH}/oauth/token`);
    if (url.pathname === "/oauth/register") return json(res, 404, { error: "dynamic_registration_disabled" });

    if (url.pathname === "/mcp") {
      if (req.method === "OPTIONS") {
        res.writeHead(204, {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "GET,POST,OPTIONS",
          "access-control-allow-headers": "Authorization,Content-Type,Accept,Mcp-Session-Id,Last-Event-Id",
          ...securityHeaders(),
        });
        return res.end();
      }

      if (req.method === "POST") {
        const bodyBuffer = await readBody(req);
        let parsed = null;
        try { parsed = bodyBuffer ? JSON.parse(bodyBuffer.toString("utf8")) : null; } catch {}

        if (!req.headers.authorization) {
          if (!allowUnauthenticatedProbe(req)) return json(res, 429, { error: "rate_limited" }, { "retry-after": "60" });
          if (publicDiscoveryResponse(res, parsed)) return;
          return unauthorized(res, base);
        }
        return proxy(req, res, SUPABASE_MCP, { interceptUnauthorized: true, bodyOverride: bodyBuffer });
      }

      if (!req.headers.authorization) {
        res.writeHead(405, {
          "allow": "POST, OPTIONS",
          "cache-control": "no-store",
          ...securityHeaders(),
        });
        return res.end();
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
      return res.end();
    }

    json(res, 404, { error: "not_found" });
  } catch (error) {
    const code = error instanceof Error && error.message === "request_too_large" ? "request_too_large" : "compatibility_proxy_error";
    json(res, code === "request_too_large" ? 413 : 502, { error: code });
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Meterion Control Room OAuth compatibility service listening on ${PORT}`);
});
