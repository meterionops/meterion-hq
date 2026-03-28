import React from "react";
import { SourceCaseTimelineItem } from "./decisionSurfaceTypes";

export const CaseTimelineCard: React.FC<{ items?: SourceCaseTimelineItem[] }> = ({ items }) => {
  if (!items || items.length === 0) {
    return <div><h3>Case Timeline</h3><p>No timeline entries yet</p></div>;
  }

  return (
    <div>
      <h3>Case Timeline</h3>
      {items.map((item, i) => (
        <div key={i}>
          <strong>{item.label}</strong>
          {item.status ? <> – {item.status}</> : null}
          {item.timestamp ? <> – {item.timestamp}</> : null}
        </div>
      ))}
    </div>
  );
};
