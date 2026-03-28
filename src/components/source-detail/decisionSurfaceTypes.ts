export type DecisionStatus =
  | "none"
  | "pending"
  | "proposed"
  | "approved"
  | "executing"
  | "completed"
  | "verified"
  | "failed"
  | "regressed";

export type DecisionConfidence = "low" | "medium" | "high";

export type DecisionSource = "mock" | "external" | "human";

export type Executor = "none" | "human" | "openclaw";

export type ExecutionStatus =
  | "idle"
  | "pending"
  | "running"
  | "completed"
  | "failed"
  | "inconclusive";

/**
 * Evidence surface
 * What is currently known from source evidence and signal-level observations.
 */
export type EvidenceSummary = {
  fetchStatus?: string;
  eventsFound?: number;
  datesFound?: number;
  mappedEventsFound?: number;
  analyzerConfidence?: string | number;
  patternLabel?: string;
  patternConfidence?: string;
  candidateSetCount?: number;
  candidateQuality?: string;
  rawHtmlVerdict?: string;
  renderedDomVerdict?: string;
  notes?: string[];
};

/**
 * Guardrail surface
 * What is safe, what requires approval, and what is blocked.
 */
export type ActionGuardrails = {
  safeActions?: string[];
  approvalRequired?: string[];
  blockedActions?: string[];
  notes?: string[];
};

/**
 * Current supervisory decision surface.
 * CityOS displays this if present, but does not generate it internally.
 */
export type SourceDecisionSurface = {
  status?: DecisionStatus;
  decisionId?: string;
  updatedAt?: string;
  decisionSource?: DecisionSource;
  requestedBy?: string;

  diagnosis?: {
    primaryHypothesis?: string;
    secondaryHypothesis?: string;
    confidence?: DecisionConfidence;
    rationaleSummary?: string;
  };

  nextStep?: {
    actionType?: string;
    actionLabel?: string;
    executor?: Executor;
    whyThisNow?: string;
  };

  constraints?: {
    doNotTouch?: string[];
    mustPreserve?: string[];
  };

  verification?: {
    successCriteria?: string[];
    regressionChecks?: string[];
  };

  approval?: {
    required?: boolean;
    reason?: string;
  };

  uncertainty?: {
    evidenceGaps?: string[];
    notes?: string;
  };
};

/**
 * Passive execution surface.
 * Displays the latest execution state if available.
 */
export type SourceExecutionSurface = {
  executor?: Executor;
  executionStatus?: ExecutionStatus;
  actionType?: string;
  actionLabel?: string;
  summary?: string;
  updatedAt?: string;
  lastTaskId?: string;

  scopeIntegrity?: {
    configChanged?: boolean;
    parserChanged?: boolean;
    runnerChanged?: boolean;
  };
};

/**
 * Decision history item.
 */
export type SourceDecisionHistoryItem = {
  decisionId?: string;
  status?: Exclude<DecisionStatus, "none">;
  primaryHypothesis?: string;
  executor?: Executor;
  updatedAt?: string;
  decisionSource?: DecisionSource;
};

/**
 * Execution history item.
 */
export type SourceExecutionHistoryItem = {
  taskId?: string;
  executor?: Executor;
  executionStatus?: Exclude<ExecutionStatus, "idle">;
  actionType?: string;
  actionLabel?: string;
  summary?: string;
  updatedAt?: string;
};

/**
 * Timeline item for source/case-level recent activity.
 */
export type SourceCaseTimelineItem = {
  kind?: "decision" | "execution" | "verification" | "note";
  label: string;
  status?: string;
  timestamp?: string;
  summary?: string;
};

/**
 * Optional wrapper surfaces.
 * Useful later if backend payloads or adapters are standardized.
 */
export type SourceDecisionHistorySurface = {
  items?: SourceDecisionHistoryItem[];
  totalCount?: number;
};

export type SourceExecutionHistorySurface = {
  items?: SourceExecutionHistoryItem[];
  totalCount?: number;
};

export type SourceCaseTimelineSurface = {
  items?: SourceCaseTimelineItem[];
  totalCount?: number;
};

export const DECISION_STATUS_ORDER: DecisionStatus[] = [
  "none",
  "pending",
  "proposed",
  "approved",
  "executing",
  "completed",
  "verified",
  "failed",
  "regressed",
];

export function formatLabel(value?: string | number | null): string {
  if (value === null || value === undefined || value === "") return "—";

  return String(value)
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

export function formatBoolean(value?: boolean): string {
  if (value === true) return "Yes";
  if (value === false) return "No";
  return "Unknown";
}

export function getDecisionStatusIndex(status?: DecisionStatus): number {
  if (!status) return 0;
  const index = DECISION_STATUS_ORDER.indexOf(status);
  return index >= 0 ? index : 0;
}
// --- Operator Guidance (non-authoritative, local hint layer) ---

export type OperatorGuidance = {
  status?: "none" | "available";
  summary?: string;
  suggestedCheck?: string;
  rationale?: string;
  doNotChangeYet?: string[];
  confidence?: "low" | "medium" | "high";
};

export type SourceOperatorGuidanceSurface = {
  guidance: OperatorGuidance | null;
};
