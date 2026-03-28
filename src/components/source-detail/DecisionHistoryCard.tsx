import React from "react";
import { SourceDecisionHistoryItem } from "./decisionSurfaceTypes";

export const DecisionHistoryCard: React.FC<{ items?: SourceDecisionHistoryItem[] }> = ({ items }) => {
  if (!items || items.length === 0) {
    return <div><h3>Decision History</h3><p>No decision history yet</p></div>;
  }

  return (
    <div>
      <h3>Decision History</h3>
      {items.map((item, i) => (
        <div key={i}>
          {item.status} – {item.primaryHypothesis}
        </div>
      ))}
    </div>
  );
};
