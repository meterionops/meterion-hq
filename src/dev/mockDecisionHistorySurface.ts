import { SourceDecisionHistoryItem } from "../components/source-detail/decisionSurfaceTypes";

export const mockDecisionHistorySurface: SourceDecisionHistoryItem[] = [
  {
    decisionId: "decision-001",
    status: "proposed",
    primaryHypothesis: "rendering_not_confirmed",
    executor: "openclaw",
    updatedAt: new Date().toISOString(),
  },
  {
    decisionId: "decision-000",
    status: "pending",
    primaryHypothesis: "insufficient_evidence",
    executor: "none",
    updatedAt: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
  },
];
