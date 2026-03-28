import { ActionGuardrails } from "../components/source-detail/decisionSurfaceTypes";

export const mockActionGuardrails: ActionGuardrails = {
  safeActions: [
    "investigate",
    "replay",
    "probe",
    "verify",
  ],
  approvalRequired: [
    "adapter_switch",
    "parser_change",
    "global_config_change",
  ],
  blockedActions: [
    "runner_change",
  ],
  notes: [
    "CityOS displays guardrails only and does not make decisions.",
    "OpenClaw execution should remain bounded to approved operational scope.",
  ],
};

export default mockActionGuardrails;
