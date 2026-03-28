import { SourceCaseTimelineItem } from "../components/source-detail/decisionSurfaceTypes";

export const mockCaseTimelineSurface: SourceCaseTimelineItem[] = [
  {
    kind: "decision",
    label: "Decision proposed",
    status: "proposed",
    timestamp: new Date(Date.now() - 1000 * 60 * 70).toISOString(),
    summary: "Pertti proposed a rendering investigation for the source.",
  },
  {
    kind: "execution",
    label: "Execution completed",
    status: "completed",
    timestamp: new Date(Date.now() - 1000 * 60 * 20).toISOString(),
    summary: "OpenClaw completed HTML vs DOM investigation.",
  },
  {
    kind: "verification",
    label: "Verification pending",
    status: "pending",
    timestamp: new Date().toISOString(),
    summary: "Awaiting confirmation of the next safe follow-up step.",
  },
];

export default mockCaseTimelineSurface;
