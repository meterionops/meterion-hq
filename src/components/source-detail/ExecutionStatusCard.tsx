import React from "react";
import { SourceExecutionSurface } from "./decisionSurfaceTypes";

type Props = {
  execution?: SourceExecutionSurface | null;
};

export const ExecutionStatusCard: React.FC<Props> = ({ execution }) => {
  if (!execution) {
    return (
      <div>
        <h3>Execution</h3>
        <p>No execution recorded yet</p>
      </div>
    );
  }

  return (
    <div>
      <h3>Execution</h3>

      <div>
        <strong>Status:</strong> {execution.executionStatus || "unknown"}
      </div>

      <div>
        <strong>Executor:</strong> {execution.executor || "none"}
      </div>

      {execution.actionLabel && (
        <div>
          <strong>Action:</strong> {execution.actionLabel}
        </div>
      )}

      {execution.summary && (
        <div>
          <strong>Summary:</strong> {execution.summary}
        </div>
      )}

      {execution.scopeIntegrity && (
        <div>
          <strong>Scope integrity:</strong>
          <ul>
            <li>configChanged: {String(execution.scopeIntegrity.configChanged)}</li>
            <li>parserChanged: {String(execution.scopeIntegrity.parserChanged)}</li>
            <li>runnerChanged: {String(execution.scopeIntegrity.runnerChanged)}</li>
          </ul>
        </div>
      )}
    </div>
  );
};
