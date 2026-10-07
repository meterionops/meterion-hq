import { withSupabase } from "npm:@supabase/server";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@6.1.0";

import { readOfficePortfolio } from "./office-portfolio.mjs";
import { hasCurrentOwnerAccess } from "./current-owner.mjs";

type JsonObject = Record<string, unknown>;

type ReadAction =
  | "get_project_state"
  | "get_projects"
  | "get_projects_overview"
  | "get_today"
  | "get_owner_attention"
  | "get_state_reconciliation"
  | "get_resume_packet"
  | "get_project_tracking"
  | "get_project_tracking_surface"
  | "get_tracking_changes"
  | "get_office_portfolio";

const AI_OS_ISSUER = "https://yokcfxcbomuaupxxxoha.supabase.co/auth/v1";
const AI_OS_JWKS = createRemoteJWKSet(
  new URL("https://yokcfxcbomuaupxxxoha.supabase.co/auth/v1/.well-known/jwks.json"),
);
const METERION_ORGANIZATION_ID = "2e737407-7aa5-4567-a8bf-0d110cfef2ae";
const METERION_OWNER_USER_ID = "06ba24f1-556e-4e41-a735-79c94d20d3b0";
const PROJECT_KEY_RE = /^[a-z0-9][a-z0-9-]*$/;
const MAX_BODY_BYTES = 16_384;

function isObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function allowedOrigin(request: Request): string | null {
  const origin = request.headers.get("origin");
  if (!origin) return null;
  try {
    const url = new URL(origin);
    if (url.protocol !== "https:" && url.hostname !== "localhost") return null;
    if (
      url.hostname === "ai-company-os-ceo-dashboard.vercel.app" ||
      url.hostname.endsWith(".vercel.app") ||
      url.hostname === "localhost"
    ) return origin;
  } catch {}
  return null;
}

function responseHeaders(request: Request): HeadersInit {
  const origin = allowedOrigin(request);
  return {
    "cache-control": "no-store",
    "content-type": "application/json; charset=utf-8",
    "vary": "Origin",
    ...(origin
      ? {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "POST, OPTIONS",
          "access-control-allow-headers": "Authorization, Content-Type",
          "access-control-max-age": "600",
        }
      : {}),
  };
}

function json(request: Request, status: number, body: JsonObject): Response {
  return Response.json(body, { status, headers: responseHeaders(request) });
}

async function parseBody(request: Request): Promise<JsonObject> {
  const text = await request.text();
  if (new TextEncoder().encode(text).byteLength > MAX_BODY_BYTES) {
    throw new Error("request_too_large");
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(text || "{}");
  } catch {
    throw new Error("invalid_json");
  }
  if (!isObject(parsed)) throw new Error("invalid_json_object");
  return parsed;
}

function projectKey(value: unknown): string {
  if (typeof value !== "string" || !PROJECT_KEY_RE.test(value)) {
    throw new Error("invalid_project_key");
  }
  return value;
}

async function verifyMeterionOwner(request: Request): Promise<{ userId: string } | null> {
  const authorization = request.headers.get("authorization") ?? "";
  const match = authorization.match(/^Bearer\s+(\S+)$/i);
  if (!match) return null;

  try {
    const { payload } = await jwtVerify(match[1], AI_OS_JWKS, {
      issuer: AI_OS_ISSUER,
      audience: "authenticated",
    });

    const appMetadata = isObject(payload.app_metadata) ? payload.app_metadata : {};
    const organizationId =
      typeof appMetadata.organization_id === "string" ? appMetadata.organization_id : "";
    const workspaceRole =
      typeof appMetadata.workspace_role === "string" ? appMetadata.workspace_role : "";
    const userId = typeof payload.sub === "string" ? payload.sub : "";

    if (
      userId !== METERION_OWNER_USER_ID ||
      organizationId !== METERION_ORGANIZATION_ID ||
      workspaceRole !== "owner"
    ) {
      return null;
    }

    if (!(await hasCurrentOwnerAccess(match[1], userId))) return null;
    return { userId };
  } catch {
    return null;
  }
}

export default {
  fetch: withSupabase({ auth: "none" }, async (request, ctx) => {
    const requestId = crypto.randomUUID();

    if (request.method === "OPTIONS") {
      const origin = allowedOrigin(request);
      if (!origin) return new Response(null, { status: 403, headers: responseHeaders(request) });
      return new Response(null, { status: 204, headers: responseHeaders(request) });
    }

    if (request.method !== "POST") {
      return json(request, 405, { ok: false, code: "method_not_allowed", request_id: requestId });
    }

    const owner = await verifyMeterionOwner(request);
    if (!owner) {
      return json(request, 401, { ok: false, code: "owner_session_required", request_id: requestId });
    }

    let body: JsonObject;
    try {
      body = await parseBody(request);
    } catch (error) {
      return json(request, error instanceof Error && error.message === "request_too_large" ? 413 : 400, {
        ok: false,
        code: error instanceof Error ? error.message : "invalid_request",
        request_id: requestId,
      });
    }

    const action = body.action;
    const allowedActions: ReadAction[] = [
      "get_project_state",
      "get_projects",
      "get_projects_overview",
      "get_today",
      "get_owner_attention",
      "get_state_reconciliation",
      "get_resume_packet",
      "get_project_tracking",
      "get_project_tracking_surface",
      "get_tracking_changes",
      "get_office_portfolio",
    ];
    if (typeof action !== "string" || !allowedActions.includes(action as ReadAction)) {
      return json(request, 400, { ok: false, code: "unknown_or_missing_action", request_id: requestId });
    }

    const admin = ctx.supabaseAdmin;
    let result: { data: unknown; error: { message: string } | null };

    try {
      switch (action as ReadAction) {
        case "get_office_portfolio":
          try { result = { data: await readOfficePortfolio(admin, METERION_ORGANIZATION_ID), error: null }; }
          catch { result = { data: null, error: { message: "office_source_unavailable" } }; }
          break;
        case "get_project_state":
          result = await admin.rpc("control_room_get_project_state_v3", {
            p_project_key: projectKey(body.project_key),
          });
          break;
        case "get_projects":
          result = await admin.rpc("control_room_get_projects_surface_v3", {
            p_projects_section: typeof body.projects_section === "string" ? body.projects_section : null,
            p_portfolio_class: typeof body.portfolio_class === "string" ? body.portfolio_class : null,
            p_state_freshness: typeof body.state_freshness === "string" ? body.state_freshness : null,
          });
          break;
        case "get_projects_overview":
          result = await admin.rpc("control_room_get_projects_overview_v2");
          break;
        case "get_today":
          result = await admin.rpc("control_room_get_today_v2");
          break;
        case "get_owner_attention":
          result = await admin.rpc("control_room_get_owner_attention_v1");
          break;
        case "get_state_reconciliation":
          result = await admin.rpc("control_room_get_state_reconciliation_v1", {
            p_due_only: body.due_only === undefined ? true : body.due_only === true,
            p_portfolio_class: typeof body.portfolio_class === "string" ? body.portfolio_class : null,
          });
          break;
        case "get_resume_packet":
          result = await admin.rpc("control_room_get_resume_packet_v2", {
            p_project_key: projectKey(body.project_key),
          });
          break;
        case "get_project_tracking":
          result = await admin.rpc("control_room_get_project_tracking_v1", {
            p_project_key: projectKey(body.project_key),
          });
          break;
        case "get_project_tracking_surface":
          result = await admin.rpc("control_room_get_project_tracking_surface_v1", {
            p_portfolio_class: typeof body.portfolio_class === "string" ? body.portfolio_class : null,
            p_lifecycle_status: typeof body.lifecycle_status === "string" ? body.lifecycle_status : null,
            p_changed_since: typeof body.changed_since === "string" ? body.changed_since : null,
          });
          break;
        case "get_tracking_changes":
          result = await admin.rpc("control_room_get_tracking_changes_v1", {
            p_after_sequence:
              typeof body.after_sequence === "number" && Number.isInteger(body.after_sequence) && body.after_sequence >= 0
                ? body.after_sequence
                : 0,
            p_limit:
              typeof body.limit === "number" && Number.isInteger(body.limit) && body.limit > 0
                ? Math.min(body.limit, 500)
                : 100,
          });
          break;
      }
    } catch (error) {
      return json(request, 400, {
        ok: false,
        code: error instanceof Error ? error.message : "invalid_request",
        request_id: requestId,
      });
    }

    if (result!.error) {
      const message = result!.error.message;
      const status = message.includes("project_not_found") ? 404 : 500;
      return json(request, status, {
        ok: false,
        code: status === 404 ? "project_not_found" : "control_room_read_failed",
        request_id: requestId,
      });
    }

    return json(request, 200, {
      ok: true,
      action,
      data: result!.data,
      request_id: requestId,
      auth: { source: "ai_company_os_owner", user_id: owner.userId },
    });
  }),
};