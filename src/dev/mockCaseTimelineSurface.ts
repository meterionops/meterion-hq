import { SourceCaseTimelineItem } from "../components/source-detail/decisionSurfaceTypes";

export const mockCaseTimelineSurface: SourceCaseTimelineItem[] = [
  {
    kind: "decision",
    label: "Decision proposed",
    status: "proposed",
    timestamp: new Date(Date.now() - 1000 * 60 * 70).toISOString(),
  },
  {
    kind: "execution",
    label: "Execution completed",
    status: "completed",
    timestamp: new Date(Date.now() - 1000 * 60 * 20).toISOString(),
  },
  {
    kind: "verification",
    label: "Verification pending",
    status: "pending",
    timestamp: new Date().toISOString(),
  },
];
