import { SourceExecutionHistoryItem } from "../components/source-detail/decisionSurfaceTypes";

export const mockExecutionHistorySurface: SourceExecutionHistoryItem[] = [
  {
    taskId: "task-001",
    executor: "openclaw",
    executionStatus: "completed",
    actionLabel: "check_html_vs_js",
    summary: "Rendered DOM contains event markers, raw HTML does not",
    updatedAt: new Date().toISOString(),
  },
  {
    taskId: "task-000",
    executor: "openclaw",
    executionStatus: "inconclusive",
    actionLabel: "initial_probe",
    summary: "Root page fetched successfully but event structure remained unclear",
    updatedAt: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
  },
];
