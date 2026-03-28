import { SourceDecisionHistoryItem } from "../components/source-detail/decisionSurfaceTypes";

export const mockDecisionHistorySurface: SourceDecisionHistoryItem[] = [
  {
    decisionId: "decision-002",
    status: "proposed",
    primaryHypothesis: "rendering_not_confirmed",
    executor: "openclaw",
    updatedAt: new Date().toISOString(),
    decisionSource: "mock",
  },
  {
    decisionId: "decision-001",
    status: "pending",
    primaryHypothesis: "insufficient_evidence",
    executor: "none",
    updatedAt: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
    decisionSource: "mock",
  },
];

export default mockDecisionHistorySurface;
