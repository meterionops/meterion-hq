import { createSupabaseContext } from "npm:@supabase/server";
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  createMcpHandler,
  hostHeaderValidationResponse,
  McpServer,
  OAuthError,
  OAuthErrorCode,
  requireBearerAuth,
} from "npm:@modelcontextprotocol/server";
import * as z from "npm:zod/v4";

const PROJECT_REF = "cavvdvxicadgfftbziao";
const PROJECT_HOST = `${PROJECT_REF}.supabase.co`;
const SUPABASE_URL = `https://${PROJECT_HOST}`;
const AUTHORIZATION_SERVER = `${SUPABASE_URL}/auth/v1`;
const MCP_URL = `${SUPABASE_URL}/functions/v1/control-room-mcp-v1`;

// Important: use a path-based RFC 9728 resource metadata endpoint, not a
// query-string endpoint. ChatGPT's MCP OAuth discovery expects a real
// protected-resource surface and follows the WWW-Authenticate pointer here.
const RESOURCE_METADATA_URL = `${MCP_URL}/oauth-protected-resource`;

const PROJECT_KEY_RE = /^[a-z0-9][a-z0-9-]*$/;

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

  const key =
    Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!key) throw new Error("missing_supabase_secret_key");
  return key;
}

const admin = createClient(SUPABASE_URL, secretKey(), {
  auth: { autoRefreshToken: false, persistSession: false },
});

function asObject(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};
}

function toolResult(data: unknown) {
  return {
    content: [{ type: "text" as const, text: JSON.stringify(data) }],
  };
}

function toolError(code: string, message: string) {
  return {
    isError: true,
    content: [
      {
        type: "text" as const,
        text: JSON.stringify({ ok: false, code, message }),
      },
    ],
  };
}

function mapRpcError(message: string): { code: string; message: string } {
  if (message.includes("state_version_conflict")) {
    return {
      code: "state_version_conflict",
      message:
        "Project state changed after it was read. Re-read current state and reconcile before writing.",
    };
  }
  if (message.includes("project_not_found")) {
    return {
      code: "project_not_found",
      message: "Unknown Control Room project.",
    };
  }
  if (
    message.includes("state_object_required") ||
    message.includes("event_object_required") ||
    message.includes("event_summary_required") ||
    message.includes("violates check constraint") ||
    message.includes("invalid input syntax")
  ) {
    return {
      code: "invalid_payload",
      message: "The proposed Control Room update is invalid.",
    };
  }
  return {
    code: "control_room_rpc_error",
    message: "Control Room could not complete the operation.",
  };
}

async function verifyAccessToken(token: string) {
  const verifyRequest = new Request(MCP_URL, {
    headers: { Authorization: `Bearer ${token}` },
  });

  const { data: ctx, error } = await createSupabaseContext(verifyRequest, {
    auth: "user",
  });

  if (error || !ctx) {
    throw new OAuthError(
      OAuthErrorCode.InvalidToken,
      "Invalid or expired Control Room access token",
    );
  }

  const claims = asObject(ctx.jwtClaims);
  const userId =
    (typeof ctx.userClaims?.id === "string" && ctx.userClaims.id) ||
    (typeof claims.sub === "string" && claims.sub) ||
    "";
  const expiresAt = Number(claims.exp);

  if (!userId || !Number.isFinite(expiresAt)) {
    throw new OAuthError(OAuthErrorCode.InvalidToken, "Incomplete access token");
  }

  const { data: operator, error: operatorError } = await ctx.supabaseAdmin
    .from("control_room_operators")
    .select("role, active")
    .eq("user_id", userId)
    .eq("active", true)
    .maybeSingle();

  if (operatorError || !operator) {
    throw new OAuthError(
      OAuthErrorCode.InvalidToken,
      "This user is not enrolled as a Meterion Control Room operator",
    );
  }

  const oauthClientId =
    typeof claims.client_id === "string" && claims.client_id.length > 0
      ? claims.client_id
      : userId;

  return {
    token,
    clientId: oauthClientId,
    scopes: [],
    expiresAt,
  };
}

const authGate = requireBearerAuth({
  verifier: { verifyAccessToken },
  requiredScopes: [],
  resourceMetadataUrl: new URL(RESOURCE_METADATA_URL),
});

function buildServer() {
  const server = new McpServer({
    name: "Meterion Control Room",
    version: "1.0.1",
  });

  server.registerTool(
    "get_project_state",
    {
      title: "Get project state",
      description:
        "Read the current canonical Control Room state for one Meterion project before continuing substantial work.",
      inputSchema: z.object({
        project_key: z.string().regex(PROJECT_KEY_RE),
      }),
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      },
    },
    async ({ project_key }) => {
      const { data, error } = await admin.rpc(
        "control_room_get_project_state_v1",
        { p_project_key: project_key },
      );
      if (error) {
        const mapped = mapRpcError(error.message);
        return toolError(mapped.code, mapped.message);
      }
      if (data === null) {
        return toolError("project_not_found", "Unknown Control Room project.");
      }
      return toolResult({ ok: true, project: data });
    },
  );

  server.registerTool(
    "list_projects",
    {
      title: "List Meterion projects",
      description:
        "List Control Room project summaries, optionally filtered by portfolio class or lifecycle status.",
      inputSchema: z.object({
        portfolio_class: z
          .enum([
            "CORE",
            "EXPERIMENT",
            "AUTOPILOT",
            "MAINTENANCE",
            "VAULT",
            "SYSTEM",
            "UNCONFIRMED",
          ])
          .optional(),
        lifecycle_status: z
          .enum(["active", "paused", "completed", "archived", "unconfirmed"])
          .optional(),
      }),
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      },
    },
    async ({ portfolio_class, lifecycle_status }) => {
      const { data, error } = await admin.rpc("control_room_list_projects_v1", {
        p_portfolio_class: portfolio_class ?? null,
        p_lifecycle_status: lifecycle_status ?? null,
      });
      if (error) {
        const mapped = mapRpcError(error.message);
        return toolError(mapped.code, mapped.message);
      }
      return toolResult({ ok: true, projects: data ?? [] });
    },
  );

  server.registerTool(
    "get_today",
    {
      title: "Get Meterion Today",
      description:
        "Read the canonical Today priority surface. Use this first when the user asks what needs attention or what to work on now.",
      inputSchema: z.object({}),
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      },
    },
    async () => {
      const { data, error } = await admin.rpc("control_room_get_today_v1");
      if (error) {
        const mapped = mapRpcError(error.message);
        return toolError(mapped.code, mapped.message);
      }
      return toolResult({ ok: true, today: data ?? [] });
    },
  );

  server.registerTool(
    "get_owner_attention",
    {
      title: "Get owner attention",
      description:
        "Return only active project states that currently require an explicit Founder action or decision.",
      inputSchema: z.object({}),
      annotations: {
        readOnlyHint: true,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: false,
      },
    },
    async () => {
      const { data, error } = await admin.rpc(
        "control_room_get_owner_attention_v1",
      );
      if (error) {
        const mapped = mapRpcError(error.message);
        return toolError(mapped.code, mapped.message);
      }
      return toolResult({ ok: true, owner_attention: data ?? [] });
    },
  );

  server.registerTool(
    "update_project_state",
    {
      title: "Update project state",
      description:
        "Append a new operational state version after a meaningful work batch. Never use this to change Owner-controlled goal, portfolio class, lifecycle or locked constraints.",
      inputSchema: z.object({
        project_key: z.string().regex(PROJECT_KEY_RE),
        expected_version: z.number().int().nonnegative(),
        state: z
          .object({
            phase: z.string().max(500).optional(),
            current_focus: z.string().max(4000).optional(),
            last_material_result: z.string().max(4000).optional(),
            next_best_action: z.string().max(4000).optional(),
            blocked: z.boolean().optional(),
            blocker_summary: z.string().max(4000).nullable().optional(),
            autonomy_state: z
              .enum([
                "working",
                "can_continue",
                "waiting",
                "owner_needed",
                "inactive",
              ])
              .optional(),
            autonomy_reason: z.string().max(4000).nullable().optional(),
            founder_attention_required: z.boolean().optional(),
            founder_gate: z
              .enum([
                "none",
                "strategic_decision",
                "credential",
                "legal_commercial",
                "external_communication",
                "contract",
                "customer_data",
                "production_mutation",
                "spend",
                "live_money",
              ])
              .optional(),
            founder_attention_reason: z
              .string()
              .max(4000)
              .nullable()
              .optional(),
            founder_attention_unlocks: z
              .string()
              .max(4000)
              .nullable()
              .optional(),
            confidence: z.enum(["low", "medium", "high"]).optional(),
            verified_at: z.string().max(100).optional(),
            source_type: z.string().max(100).optional(),
            source_ref: z.string().max(1000).nullable().optional(),
          })
          .strict(),
      }),
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: false,
        openWorldHint: false,
      },
    },
    async ({ project_key, expected_version, state }) => {
      const { data, error } = await admin.rpc(
        "control_room_append_project_state_v1",
        {
          p_project_key: project_key,
          p_expected_version: expected_version,
          p_state: state,
        },
      );
      if (error) {
        const mapped = mapRpcError(error.message);
        return toolError(mapped.code, mapped.message);
      }
      return toolResult({ ok: true, state: data });
    },
  );

  server.registerTool(
    "append_project_event",
    {
      title: "Append material project event",
      description:
        "Append a material project event only when it changes future orientation. Do not log routine prompts, API calls or granular work rows.",
      inputSchema: z.object({
        project_key: z.string().regex(PROJECT_KEY_RE),
        event: z
          .object({
            event_type: z.string().min(1).max(100).optional(),
            summary: z.string().min(1).max(4000),
            importance: z
              .enum(["low", "normal", "high", "critical"])
              .optional(),
            occurred_at: z.string().max(100).optional(),
            source_type: z.string().max(100).optional(),
            source_ref: z.string().max(1000).nullable().optional(),
            metadata: z.record(z.string(), z.unknown()).optional(),
          })
          .strict(),
      }),
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: false,
        openWorldHint: false,
      },
    },
    async ({ project_key, event }) => {
      const { data, error } = await admin.rpc(
        "control_room_append_project_event_v1",
        {
          p_project_key: project_key,
          p_event: event,
        },
      );
      if (error) {
        const mapped = mapRpcError(error.message);
        return toolError(mapped.code, mapped.message);
      }
      return toolResult({ ok: true, event: data });
    },
  );

  return server;
}

const mcpHandler = createMcpHandler(buildServer);

function resourceMetadataResponse(method: string): Response {
  const headers = {
    "access-control-allow-origin": "*",
    "access-control-allow-methods": "GET, OPTIONS",
    "access-control-allow-headers": "Authorization, Content-Type",
    "cache-control": "public, max-age=300",
    "content-type": "application/json; charset=utf-8",
  };

  if (method === "OPTIONS") {
    return new Response(null, { status: 204, headers });
  }

  return Response.json(
    {
      resource: MCP_URL,
      authorization_servers: [AUTHORIZATION_SERVER],
      scopes_supported: ["email"],
      bearer_methods_supported: ["header"],
      resource_name: "Meterion Control Room",
    },
    { headers },
  );
}

function isProtectedResourceMetadataRequest(url: URL): boolean {
  // Primary route matches Supabase's current OAuth protected-resource middleware.
  if (url.pathname.endsWith("/oauth-protected-resource")) return true;

  // Also answer path-local well-known probes used by some MCP clients.
  if (url.pathname.includes("/.well-known/oauth-protected-resource")) return true;

  return false;
}

export default {
  async fetch(request: Request): Promise<Response> {
    const hostRejected = hostHeaderValidationResponse(request, [PROJECT_HOST]);
    if (hostRejected) return hostRejected;

    const url = new URL(request.url);
    if (
      (request.method === "GET" || request.method === "OPTIONS") &&
      isProtectedResourceMetadataRequest(url)
    ) {
      return resourceMetadataResponse(request.method);
    }

    const auth = await authGate(request);
    if (auth instanceof Response) return auth;

    return mcpHandler.fetch(request, { authInfo: auth });
  },
};
