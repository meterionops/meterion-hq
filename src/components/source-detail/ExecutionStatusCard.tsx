import React from "react";
import {
  SourceExecutionSurface,
  formatBoolean,
  formatLabel,
} from "./decisionSurfaceTypes";

type Props = {
  execution?: SourceExecutionSurface | null;
};

const statusToneMap: Record<string, string> = {
  idle: "bg-slate-100 text-slate-700 border-slate-200",
  pending: "bg-amber-100 text-amber-800 border-amber-200",
  running: "bg-indigo-100 text-indigo-800 border-indigo-200",
  completed: "bg-emerald-100 text-emerald-800 border-emerald-200",
  failed: "bg-red-100 text-red-800 border-red-200",
  inconclusive: "bg-orange-100 text-orange-800 border-orange-200",
};

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-xl border border-slate-200 bg-white p-4">
      <h4 className="mb-3 text-sm font-semibold text-slate-900">{title}</h4>
      <div className="space-y-2 text-sm text-slate-700">{children}</div>
    </section>
  );
}

export const ExecutionStatusCard: React.FC<Props> = ({ execution }) => {
  const status = execution?.executionStatus ?? "idle";
  const tone = statusToneMap[status] ?? statusToneMap.idle;

  if (!execution) {
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="mb-4 flex items-start justify-between gap-3">
          <div>
            <h3 className="text-lg font-semibold text-slate-900">
              Execution Status
            </h3>
            <p className="mt-1 text-sm text-slate-500">
              No execution recorded yet.
            </p>
          </div>

          <span
            className={`rounded-full border px-3 py-1 text-xs font-medium ${tone}`}
          >
            {formatLabel(status)}
          </span>
        </div>

        <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
          This surface is passive. CityOS shows execution results here when they
          exist, but does not trigger execution from this card.
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div>
          <h3 className="text-lg font-semibold text-slate-900">
            Execution Status
          </h3>
          <p className="mt-1 text-sm text-slate-500">
            Latest passive execution surface for this source case.
          </p>
        </div>

        <span
          className={`inline-flex rounded-full border px-3 py-1 text-xs font-medium ${tone}`}
        >
          {formatLabel(status)}
        </span>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Section title="Execution">
          <div>
            <span className="font-medium text-slate-900">Executor:</span>{" "}
            {formatLabel(execution.executor)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Action type:</span>{" "}
            {formatLabel(execution.actionType)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Action label:</span>{" "}
            {formatLabel(execution.actionLabel)}
          </div>

          {execution.summary ? (
            <div>
              <span className="font-medium text-slate-900">Summary:</span>
              <p className="mt-1 text-slate-700">{execution.summary}</p>
            </div>
          ) : null}
        </Section>

        <Section title="Scope Integrity">
          <div>
            <span className="font-medium text-slate-900">Config changed:</span>{" "}
            {formatBoolean(execution.scopeIntegrity?.configChanged)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Parser changed:</span>{" "}
            {formatBoolean(execution.scopeIntegrity?.parserChanged)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Runner changed:</span>{" "}
            {formatBoolean(execution.scopeIntegrity?.runnerChanged)}
          </div>
        </Section>
      </div>

      {(execution.updatedAt || execution.lastTaskId) && (
        <div className="mt-4 border-t border-slate-200 pt-3 text-xs text-slate-500">
          <div className="flex flex-wrap gap-x-4 gap-y-1">
            {execution.updatedAt ? (
              <span>
                <span className="font-medium text-slate-700">Updated:</span>{" "}
                {execution.updatedAt}
              </span>
            ) : null}

            {execution.lastTaskId ? (
              <span>
                <span className="font-medium text-slate-700">Task ID:</span>{" "}
                {execution.lastTaskId}
              </span>
            ) : null}
          </div>
        </div>
      )}
    </div>
  );
};

export default ExecutionStatusCard;
