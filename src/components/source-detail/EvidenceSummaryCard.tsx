import React from "react";
import { EvidenceSummary, formatLabel } from "./decisionSurfaceTypes";

type Props = {
  summary?: EvidenceSummary | null;
};

function ValueRow({
  label,
  value,
}: {
  label: string;
  value?: string | number | null;
}) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-slate-100 py-2 last:border-b-0">
      <span className="text-sm text-slate-600">{label}</span>
      <span className="text-right text-sm font-medium text-slate-900">
        {formatLabel(value)}
      </span>
    </div>
  );
}

function EmptyState() {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-slate-900">
          Evidence Summary
        </h3>
        <p className="mt-1 text-sm text-slate-500">
          What is currently known from source evidence and signals.
        </p>
      </div>

      <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
        No evidence summary available yet.
      </div>
    </div>
  );
}

export const EvidenceSummaryCard: React.FC<Props> = ({ summary }) => {
  if (!summary) {
    return <EmptyState />;
  }

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-slate-900">
          Evidence Summary
        </h3>
        <p className="mt-1 text-sm text-slate-500">
          Current known facts and signal-level observations for this source.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <section className="rounded-xl border border-slate-200 bg-white p-4">
          <h4 className="mb-3 text-sm font-semibold text-slate-900">
            Extraction Signals
          </h4>

          <ValueRow label="Fetch status" value={summary.fetchStatus} />
          <ValueRow label="Events found" value={summary.eventsFound} />
          <ValueRow label="Dates found" value={summary.datesFound} />
          <ValueRow label="Mapped events" value={summary.mappedEventsFound} />
          <ValueRow
            label="Analyzer confidence"
            value={summary.analyzerConfidence}
          />
        </section>

        <section className="rounded-xl border border-slate-200 bg-white p-4">
          <h4 className="mb-3 text-sm font-semibold text-slate-900">
            Structure Signals
          </h4>

          <ValueRow label="Pattern label" value={summary.patternLabel} />
          <ValueRow
            label="Pattern confidence"
            value={summary.patternConfidence}
          />
          <ValueRow
            label="Candidate set count"
            value={summary.candidateSetCount}
          />
          <ValueRow label="Candidate quality" value={summary.candidateQuality} />
          <ValueRow label="Raw HTML verdict" value={summary.rawHtmlVerdict} />
          <ValueRow
            label="Rendered DOM verdict"
            value={summary.renderedDomVerdict}
          />
        </section>
      </div>

      {summary.notes && summary.notes.length > 0 ? (
        <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
          <h4 className="mb-2 text-sm font-semibold text-slate-900">Notes</h4>
          <ul className="list-disc space-y-1 pl-5 text-sm text-slate-700">
            {summary.notes.map((note, idx) => (
              <li key={`${note}-${idx}`}>{note}</li>
            ))}
          </ul>
        </div>
      ) : null}
    </div>
  );
};

export default EvidenceSummaryCard;
