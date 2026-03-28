import React from "react";
import {
  SourceDecisionHistoryItem,
  formatLabel,
} from "./decisionSurfaceTypes";

type Props = {
  items?: SourceDecisionHistoryItem[];
};

function EmptyState() {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <h3 className="text-lg font-semibold text-slate-900">Decision History</h3>
      <p className="mt-2 text-sm text-slate-500">No decision history yet.</p>
    </div>
  );
}

function HistoryRow({ item }: { item: SourceDecisionHistoryItem }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
      <div className="flex flex-col gap-2 md:flex-row md:items-start md:justify-between">
        <div className="space-y-1">
          <div className="text-sm font-medium text-slate-900">
            {formatLabel(item.status)}
          </div>

          <div className="text-sm text-slate-700">
            <span className="font-medium text-slate-900">Primary hypothesis:</span>{" "}
            {formatLabel(item.primaryHypothesis)}
          </div>

          <div className="text-sm text-slate-700">
            <span className="font-medium text-slate-900">Executor:</span>{" "}
            {formatLabel(item.executor)}
          </div>
        </div>

        <div className="text-xs text-slate-500">
          {item.updatedAt ? <div>Updated: {item.updatedAt}</div> : null}
          {item.decisionId ? <div>ID: {item.decisionId}</div> : null}
          {item.decisionSource ? (
            <div>Source: {formatLabel(item.decisionSource)}</div>
          ) : null}
        </div>
      </div>
    </div>
  );
}

export const DecisionHistoryCard: React.FC<Props> = ({ items }) => {
  if (!items || items.length === 0) {
    return <EmptyState />;
  }

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex items-start justify-between gap-3">
        <div>
          <h3 className="text-lg font-semibold text-slate-900">
            Decision History
          </h3>
          <p className="mt-1 text-sm text-slate-500">
            Previous source-level decisions for this case.
          </p>
        </div>

        <div className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs text-slate-600">
          {items.length} item{items.length === 1 ? "" : "s"}
        </div>
      </div>

      <div className="space-y-3">
        {items.map((item, index) => (
          <HistoryRow
            key={item.decisionId ?? `${item.status ?? "unknown"}-${index}`}
            item={item}
          />
        ))}
      </div>
    </div>
  );
};

export default DecisionHistoryCard;
