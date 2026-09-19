import { withSupabase } from "npm:@supabase/server";

type JsonObject = Record<string, unknown>;

type Action =
  | "get_project_state"
  | "get_projects"
  | "get_projects_overview"
  | "get_today"
  | "get_owner_attention"
  | "get_state_reconciliation"
  | "get_resume_packet"
  | "update_project_state"
  | "complete_work_batch"
  | "append_project_event";

const PROJECT_KEY_RE = /^[a-z0-9][a-z0-9-]*$/;
const MAX_BODY_BYTES = 32_768;

function json(status: number, body: JsonObject): Response {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
      "content-type": "application/json; charset=utf-8",
    },
  });
}

function isObject(value: unknown): value is JsonObject {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function optionalString(value: unknown): string | null {
  if (value === null || value === undefined || value === "") return null;
  return typeof value === "string" ? value : null;
}

function optionalBoolean(value: unknown, fallback: boolean): boolean | null {
  if (value === undefined || value === null) return fallback;
  return typeof value === "boolean" ? value : null;
}

function requireProjectKey(value: unknown): string {
  if (typeof value !== "string" || !PROJECT_KEY_RE.test(value)) {
    throw new Error("invalid_project_key");
  }
  return value;
}

function classifyRpcError(message: string): { status: number; code: string } {
  if (message.includes("state_version_conflict")) {
    return { status: 409, code: "state_version_conflict" };
  }
  if (message.includes("project_not_found")) {
    return { status: 404, code: "project_not_found" };
  }
  if (message.includes("work_batch_in_progress")) {
    return { status: 409, code: "work_batch_in_progress" };
  }
  if (
    message.includes("violates check constraint") ||
    message.includes("invalid input syntax") ||
    message.includes("event_summary_required") ||
    message.includes("event_object_required") ||
    message.includes("state_object_required") ||
    message.includes("state_patch_object_required") ||
    message.includes("control_arrays_required") ||
    message.includes("jev_result_object_required") ||
    message.includes("jev_decision_required") ||
    message.includes("invalid_jev_confidence") ||
    message.includes("invalid_batch_key") ||
    message.includes("invalid_expected_version") ||
    message.includes("event_metadata_object_required")
  ) {
    return { status: 400, code: "invalid_payload" };
  }
  return { status: 500, code: "control_room_rpc_error" };
}

async function parseBody(req: Request): Promise<JsonObject> {
  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > MAX_BODY_BYTES) {
    throw new Error("request_too_large");
  }

  const text = await req.text();
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

export default {
  fetch: withSupabase({ auth: "secret" }, async (req, ctx) => {
    const requestId = crypto.randomUUID();

    if (req.method !== "POST") {
      return json(405, {
        ok: false,
        code: "method_not_allowed",
        request_id: requestId,
      });
    }

    let body: JsonObject;
    try {
      body = await parseBody(req);
    } catch (error) {
      const code = error instanceof Error ? error.message : "invalid_request";
      return json(code === "request_too_large" ? 413 : 400, {
        ok: false,
        code,
        request_id: requestId,
      });
    }

    const action = body.action;
    if (typeof action !== "string") {
      return json(400, {
        ok: false,
        code: "action_required",
        request_id: requestId,
      });
    }

    const allowedActions: Action[] = [
      "get_project_state",
      "get_projects",
      "get_projects_overview",
      "get_today",
      "get_owner_attention",
      "get_state_reconciliation",
      "get_resume_packet",
      "update_project_state",
      "complete_work_batch",
      "append_project_event",
    ];

    if (!allowedActions.includes(action as Action)) {
      return json(400, {
        ok: false,
        code: "unknown_action",
        request_id: requestId,
      });
    }

    const admin = ctx.supabaseAdmin;
    let result: { data: unknown; error: { message: string } | null };

    try {
      switch (action as Action) {
        case "get_project_state": {
          const projectKey = requireProjectKey(body.project_key);
          result = await admin.rpc("control_room_get_project_state_v3", {
            p_project_key: projectKey,
          });
          break;
        }

        case "get_projects": {
          const projectsSection = optionalString(body.projects_section);
          const portfolioClass = optionalString(body.portfolio_class);
          const stateFreshness = optionalString(body.state_freshness);

          if (
            (body.projects_section !== undefined && projectsSection === null) ||
            (body.portfolio_class !== undefined && portfolioClass === null) ||
            (body.state_freshness !== undefined && stateFreshness === null)
          ) {
            return json(400, {
              ok: false,
              code: "invalid_filter",
              request_id: requestId,
            });
          }

          result = await admin.rpc("control_room_get_projects_surface_v3", {
            p_projects_section: projectsSection,
            p_portfolio_class: portfolioClass,
            p_state_freshness: stateFreshness,
          });
          break;
        }

        case "get_projects_overview": {
          result = await admin.rpc("control_room_get_projects_overview_v2");
          break;
        }

        case "get_today": {
          result = await admin.rpc("control_room_get_today_v2");
          break;
        }

        case "get_owner_attention": {
          result = await admin.rpc("control_room_get_owner_attention_v1");
          break;
        }

        case "get_state_reconciliation": {
          const dueOnly = optionalBoolean(body.due_only, true);
          const portfolioClass = optionalString(body.portfolio_class);
          if (
            dueOnly === null ||
            (body.portfolio_class !== undefined && portfolioClass === null)
          ) {
            return json(400, {
              ok: false,
              code: "invalid_filter",
              request_id: requestId,
            });
          }

          result = await admin.rpc("control_room_get_state_reconciliation_v1", {
            p_due_only: dueOnly,
            p_portfolio_class: portfolioClass,
          });
          break;
        }

        case "get_resume_packet": {
          const projectKey = requireProjectKey(body.project_key);
          result = await admin.rpc("control_room_get_resume_packet_v2", {
            p_project_key: projectKey,
          });
          break;
        }

        case "update_project_state": {
          const projectKey = requireProjectKey(body.project_key);
          const expectedVersion = body.expected_version;
          if (!Number.isInteger(expectedVersion) || (expectedVersion as number) < 0) {
            return json(400, {
              ok: false,
              code: "invalid_expected_version",
              request_id: requestId,
            });
          }
          if (!isObject(body.state)) {
            return json(400, {
              ok: false,
              code: "state_object_required",
              request_id: requestId,
            });
          }

          result = await admin.rpc("control_room_patch_project_state_v1", {
            p_project_key: projectKey,
            p_expected_version: expectedVersion,
            p_state_patch: body.state,
          });
          break;
        }

        case "complete_work_batch": {
          const projectKey = requireProjectKey(body.project_key);
          const expectedVersion = body.expected_version;
          const batchKey = body.batch_key;

          if (!Number.isInteger(expectedVersion) || (expectedVersion as number) < 0) {
            return json(400, {
              ok: false,
              code: "invalid_expected_version",
              request_id: requestId,
            });
          }
          if (typeof batchKey !== "string" || batchKey.trim().length === 0 || batchKey.length > 200) {
            return json(400, {
              ok: false,
              code: "invalid_batch_key",
              request_id: requestId,
            });
          }
          if (!isObject(body.state_patch)) {
            return json(400, {
              ok: false,
              code: "state_patch_object_required",
              request_id: requestId,
            });
          }
          if (!isObject(body.event) || typeof body.event.summary !== "string" || body.event.summary.trim().length === 0) {
            return json(400, {
              ok: false,
              code: "event_summary_required",
              request_id: requestId,
            });
          }
          if (body.jev_result !== undefined && body.jev_result !== null && !isObject(body.jev_result)) {
            return json(400, {
              ok: false,
              code: "jev_result_object_required",
              request_id: requestId,
            });
          }

          result = await admin.rpc("control_room_complete_work_batch_v1", {
            p_project_key: projectKey,
            p_expected_version: expectedVersion,
            p_batch_key: batchKey,
            p_state_patch: body.state_patch,
            p_event: body.event,
            p_jev_result: body.jev_result ?? null,
          });
          break;
        }

        case "append_project_event": {
          const projectKey = requireProjectKey(body.project_key);
          if (!isObject(body.event)) {
            return json(400, {
              ok: false,
              code: "event_object_required",
              request_id: requestId,
            });
          }
          if (
            typeof body.event.summary !== "string" ||
            body.event.summary.trim().length === 0
          ) {
            return json(400, {
              ok: false,
              code: "event_summary_required",
              request_id: requestId,
            });
          }

          result = await admin.rpc("control_room_append_project_event_v1", {
            p_project_key: projectKey,
            p_event: body.event,
          });
          break;
        }
      }
    } catch (error) {
      const code = error instanceof Error ? error.message : "connector_failure";
      const status = code === "invalid_project_key" ? 400 : 500;
      return json(status, {
        ok: false,
        code,
        request_id: requestId,
      });
    }

    if (result!.error) {
      const mapped = classifyRpcError(result!.error.message);
      return json(mapped.status, {
        ok: false,
        code: mapped.code,
        request_id: requestId,
      });
    }

    return json(200, {
      ok: true,
      action,
      data: result!.data,
      request_id: requestId,
    });
  }),
};
