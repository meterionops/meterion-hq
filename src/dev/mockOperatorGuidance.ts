import { OperatorGuidance } from "@/components/source-detail/decisionSurfaceTypes";

export const mockOperatorGuidance: OperatorGuidance = {
  status: "available",
  summary: "No supervisory decision exists yet.",
  suggestedCheck:
    "Verify whether event data exists in raw HTML or only after JavaScript rendering.",
  rationale:
    "Current signals show successful fetch but no extractable event dates.",
  doNotChangeYet: [
    "parser",
    "runner",
    "global config",
  ],
  confidence: "low",
};
