import { SourceExecutionSurface } from "../components/source-detail/decisionSurfaceTypes";

export const mockExecutionSurface: SourceExecutionSurface = {
  executor: "openclaw",
  executionStatus: "completed",
  actionType: "investigate_rendering",
  actionLabel: "check_html_vs_js",
  summary: "Rendered DOM contains event markers, raw HTML does not",
  updatedAt: new Date().toISOString(),
  scopeIntegrity: {
    configChanged: false,
    parserChanged: false,
    runnerChanged: false,
  },
};
