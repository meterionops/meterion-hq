import React from "react";
import {
  SourceCaseTimelineItem,
  formatLabel,
} from "./decisionSurfaceTypes";

type Props = {
  items?: SourceCaseTimelineItem[];
};

function EmptyState() {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <h3 className="text-lg font-semibold text-slate-900">Case Timeline</h3>
      <p className="mt-2 text-sm text-slate-500">No timeline entries yet.</p>
    </div>
  );
}

function TimelineRow({ item }: { item: SourceCaseTimelineItem }) {
  return (
    <div className="flex gap-3">
      <div className="mt-1 h-2.5 w-2.5 shrink-0 rounded-full bg-slate-400" />
      <div className="min-w-0 flex-1 rounded-xl border border-slate-200 bg-slate-50 p-4">
        <div className="flex flex-col gap-2 md:flex-row md:items-start md:justify-between">
          <div className="space-y-1">
            <div className="text-sm font-medium text-slate-900">
              {item.label}
            </div>

            {item.kind ? (
              <div className="text-sm text-slate-700">
                <span className="font-medium text-slate-900">Kind:</span>{" "}
                {formatLabel(item.kind)}
              </div>
            ) : null}

            {item.status ? (
              <div className="text-sm text-slate-700">
                <span className="font-medium text-slate-900">Status:</span>{" "}
                {formatLabel(item.status)}
              </div>
            ) : null}

            {item.summary ? (
              <div className="text-sm text-slate-700">{item.summary}</div>
            ) : null}
          </div>

          {item.timestamp ? (
            <div className="text-xs text-slate-500">{item.timestamp}</div>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export const CaseTimelineCard: React.FC<Props> = ({ items }) => {
  if (!items || items.length === 0) {
    return <EmptyState />;
  }

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-slate-900">Case Timeline</h3>
        <p className="mt-1 text-sm text-slate-500">
          Chronological view of recent source-case activity.
        </p>
      </div>

      <div className="space-y-4">
        {items.map((item, index) => (
          <TimelineRow
            key={`${item.kind ?? "entry"}-${item.timestamp ?? index}-${index}`}
            item={item}
          />
        ))}
      </div>
    </div>
  );
};

export default CaseTimelineCard;
