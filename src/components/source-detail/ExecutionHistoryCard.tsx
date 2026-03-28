import React from "react";
import { SourceExecutionHistoryItem } from "./decisionSurfaceTypes";

export const ExecutionHistoryCard: React.FC<{ items?: SourceExecutionHistoryItem[] }> = ({ items }) => {
  if (!items || items.length === 0) {
    return <div><h3>Execution History</h3><p>No executions yet</p></div>;
  }

  return (
    <div>
      <h3>Execution History</h3>
      {items.map((item, i) => (
        <div key={i}>
          {item.executionStatus} – {item.actionLabel}
        </div>
      ))}
    </div>
  );
};
