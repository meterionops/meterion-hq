import { SourceDecisionSurface } from "../components/source-detail/decisionSurfaceTypes";

export const mockDecisionSurface: SourceDecisionSurface = {
  status: "proposed",
  decisionId: "mock-decision-1",
  updatedAt: new Date().toISOString(),
  decisionSource: "mock",
  requestedBy: "dev",
  diagnosis: {
    primaryHypothesis: "rendering_not_confirmed",
    secondaryHypothesis: "parser_mismatch",
    confidence: "medium",
    rationaleSummary: "Current evidence does not yet distinguish missing rendered content from parsing failure.",
  },
  nextStep: {
    actionType: "investigate_rendering",
    actionLabel: "check_html_vs_js",
    executor: "openclaw",
    whyThisNow: "Highest information gain with minimal system risk.",
  },
  constraints: {
    doNotTouch: ["parser", "runner", "global configs"],
    mustPreserve: ["audit_trail", "source_local_scope"],
  },
  verification: {
    successCriteria: ["HTML vs DOM verdict produced"],
    regressionChecks: ["no config mutation", "no runner mutation"],
  },
  approval: {
    required: false,
    reason: "Investigation only",
  },
  uncertainty: {
    evidenceGaps: ["raw_html_missing", "dom_check_missing"],
    notes: "Rendering not yet confirmed.",
  },
};
