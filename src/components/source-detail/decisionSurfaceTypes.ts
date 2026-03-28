export type SourceExecutionSurface = {
  executor?: "none" | "human" | "openclaw";
  executionStatus?: "idle" | "pending" | "running" | "completed" | "failed" | "inconclusive";
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
  status?: string;
  primaryHypothesis?: string;
  executor?: "none" | "human" | "openclaw";
  updatedAt?: string;
};

export type SourceExecutionHistoryItem = {
  taskId?: string;
  executor?: "none" | "human" | "openclaw";
  executionStatus?: string;
  actionLabel?: string;
  summary?: string;
  updatedAt?: string;
};

export type SourceCaseTimelineItem = {
  kind?: "decision" | "execution" | "verification";
  label: string;
  status?: string;
  timestamp?: string;
};
