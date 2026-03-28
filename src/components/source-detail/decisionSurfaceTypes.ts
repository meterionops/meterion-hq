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

export type SourceDecisionHistoryItem = {
  decisionId?: string;
  status?: Exclude<DecisionStatus, "none">;
  primaryHypothesis?: string;
  executor?: Executor;
  updatedAt?: string;
  decisionSource?: DecisionSource;
};

export type SourceExecutionHistoryItem = {
  taskId?: string;
  executor?: Executor;
  executionStatus?: Exclude<ExecutionStatus, "idle">;
  actionType?: string;
  actionLabel?: string;
  summary?: string;
  updatedAt?: string;
};

export type SourceCaseTimelineItem = {
  kind?: "decision" | "execution" | "verification" | "note";
  label: string;
  status?: string;
  timestamp?: string;
  summary?: string;
};

/**
 * Optional surface wrappers if you later want to standardize card props
 * or backend payloads.
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

/**
 * Small helper formatters for UI components.
 */
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

export function formatLabel(value?: string): string {
  if (!value) return "—";
  return value
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
