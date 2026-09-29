import { withSupabase } from "npm:@supabase/server";

type JsonObject = Record<string, unknown>;

type ReadAction =
  | "get_project_state"
  | "get_projects"
  | "get_projects_overview"
  | "get_today"
  | "get_owner_attention"
  | "get_state_reconciliation"
  | "get_resume_packet";

const AI_OS_URL = "https://yokcfxcbomuaupxxxoha.supabase.co";
const AI_OS_PUBLISHABLE_KEY = "sb_publishable_ip_oZDtDAa5hqy1kQ8TfGg_p3DCSnzj";
const METERION_ORGANIZATION_ID = "2e737407-7aa5-4567-a8bf-0d110cfef2ae";
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
  if (!/^Bearer\s+\S+$/i.test(authorization)) return null;

  const authResponse = await fetch(`${AI_OS_URL}/auth/v1/user`, {
    headers: {
      apikey: AI_OS_PUBLISHABLE_KEY,
      Authorization: authorization,
      Accept: "application/json",
    },
  });
  if (!authResponse.ok) return null;

  const user = await authResponse.json() as JsonObject;
  const userId = typeof user.id === "string" ? user.id : "";
  if (!userId) return null;

  const membershipUrl = new URL(`${AI_OS_URL}/rest/v1/organization_members`);
  membershipUrl.searchParams.set("select", "organization_id,role,status");
  membershipUrl.searchParams.set("user_id", `eq.${userId}`);
  membershipUrl.searchParams.set("organization_id", `eq.${METERION_ORGANIZATION_ID}`);
  membershipUrl.searchParams.set("status", "eq.active");
  membershipUrl.searchParams.set("limit", "1");

  const membershipResponse = await fetch(membershipUrl, {
    headers: {
      apikey: AI_OS_PUBLISHABLE_KEY,
      Authorization: authorization,
      Accept: "application/json",
    },
  });
  if (!membershipResponse.ok) return null;

  const memberships = await membershipResponse.json() as JsonObject[];
  const membership = Array.isArray(memberships) ? memberships[0] : null;
  if (!membership || membership.role !== "owner") return null;

  const organizationUrl = new URL(`${AI_OS_URL}/rest/v1/organizations`);
  organizationUrl.searchParams.set("select", "id,status");
  organizationUrl.searchParams.set("id", `eq.${METERION_ORGANIZATION_ID}`);
  organizationUrl.searchParams.set("status", "eq.active");
  organizationUrl.searchParams.set("limit", "1");

  const organizationResponse = await fetch(organizationUrl, {
    headers: {
      apikey: AI_OS_PUBLISHABLE_KEY,
      Authorization: authorization,
      Accept: "application/json",
    },
  });
  if (!organizationResponse.ok) return null;
  const organizations = await organizationResponse.json() as JsonObject[];
  if (!Array.isArray(organizations) || organizations.length !== 1) return null;

  return { userId };
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
    ];
    if (typeof action !== "string" || !allowedActions.includes(action as ReadAction)) {
      return json(request, 400, { ok: false, code: "unknown_or_missing_action", request_id: requestId });
    }

    const admin = ctx.supabaseAdmin;
    let result: { data: unknown; error: { message: string } | null };

    try {
      switch (action as ReadAction) {
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
