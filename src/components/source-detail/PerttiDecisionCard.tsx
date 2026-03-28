import React from "react";
import {
  DECISION_STATUS_ORDER,
  SourceDecisionSurface,
  formatLabel,
  getDecisionStatusIndex,
} from "./decisionSurfaceTypes";

type Props = {
  decision?: SourceDecisionSurface | null;
};

const statusToneMap: Record<string, string> = {
  none: "bg-slate-100 text-slate-700 border-slate-200",
  pending: "bg-amber-100 text-amber-800 border-amber-200",
  proposed: "bg-blue-100 text-blue-800 border-blue-200",
  approved: "bg-emerald-100 text-emerald-800 border-emerald-200",
  executing: "bg-indigo-100 text-indigo-800 border-indigo-200",
  completed: "bg-sky-100 text-sky-800 border-sky-200",
  verified: "bg-green-100 text-green-800 border-green-200",
  failed: "bg-red-100 text-red-800 border-red-200",
  regressed: "bg-rose-100 text-rose-800 border-rose-200",
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

function List({
  items,
  emptyLabel = "—",
}: {
  items?: string[];
  emptyLabel?: string;
}) {
  if (!items || items.length === 0) {
    return <p className="text-slate-500">{emptyLabel}</p>;
  }

  return (
    <ul className="list-disc space-y-1 pl-5">
      {items.map((item, idx) => (
        <li key={`${item}-${idx}`}>{item}</li>
      ))}
    </ul>
  );
}

function LifecycleBar({ status }: { status?: SourceDecisionSurface["status"] }) {
  const activeIndex = getDecisionStatusIndex(status);

  return (
    <div className="space-y-2">
      <div className="flex flex-wrap gap-2">
        {DECISION_STATUS_ORDER.map((step, idx) => {
          const isActive = idx === activeIndex;
          const isPast = idx < activeIndex;

          return (
            <div
              key={step}
              className={[
                "rounded-full border px-2.5 py-1 text-xs font-medium",
                isActive
                  ? "border-slate-900 bg-slate-900 text-white"
                  : isPast
                    ? "border-slate-300 bg-slate-100 text-slate-700"
                    : "border-slate-200 bg-white text-slate-400",
              ].join(" ")}
            >
              {formatLabel(step)}
            </div>
          );
        })}
      </div>
    </div>
  );
}

export const PerttiDecisionCard: React.FC<Props> = ({ decision }) => {
  const status = decision?.status ?? "none";
  const tone = statusToneMap[status] ?? statusToneMap.none;

  if (!decision) {
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="mb-4 flex items-start justify-between gap-3">
          <div>
            <h3 className="text-lg font-semibold text-slate-900">
              Pertti Decision
            </h3>
            <p className="mt-1 text-sm text-slate-500">
              No decision has been injected yet.
            </p>
          </div>

          <span
            className={`rounded-full border px-3 py-1 text-xs font-medium ${tone}`}
          >
            {formatLabel(status)}
          </span>
        </div>

        <LifecycleBar status={status} />

        <div className="mt-4 rounded-xl border border-dashed border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
          CityOS is not generating decisions internally. This card will render a
          real decision when an external decision object is provided.
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4 flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
        <div>
          <h3 className="text-lg font-semibold text-slate-900">
            Pertti Decision
          </h3>
          <p className="mt-1 text-sm text-slate-500">
            Current supervisory decision surface for this source case.
          </p>
        </div>

        <span
          className={`inline-flex rounded-full border px-3 py-1 text-xs font-medium ${tone}`}
        >
          {formatLabel(status)}
        </span>
      </div>

      <div className="mb-5">
        <LifecycleBar status={status} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Section title="Diagnosis">
          <div>
            <span className="font-medium text-slate-900">Primary:</span>{" "}
            {formatLabel(decision.diagnosis?.primaryHypothesis)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Secondary:</span>{" "}
            {formatLabel(decision.diagnosis?.secondaryHypothesis)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Confidence:</span>{" "}
            {formatLabel(decision.diagnosis?.confidence)}
          </div>

          {decision.diagnosis?.rationaleSummary && (
            <div>
              <span className="font-medium text-slate-900">Rationale:</span>
              <p className="mt-1 text-slate-700">
                {decision.diagnosis.rationaleSummary}
              </p>
            </div>
          )}
        </Section>

        <Section title="Next Step">
          <div>
            <span className="font-medium text-slate-900">Action type:</span>{" "}
            {formatLabel(decision.nextStep?.actionType)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Action label:</span>{" "}
            {formatLabel(decision.nextStep?.actionLabel)}
          </div>

          <div>
            <span className="font-medium text-slate-900">Executor:</span>{" "}
            {formatLabel(decision.nextStep?.executor)}
          </div>

          {decision.nextStep?.whyThisNow && (
            <div>
              <span className="font-medium text-slate-900">Why now:</span>
              <p className="mt-1 text-slate-700">
                {decision.nextStep.whyThisNow}
              </p>
            </div>
          )}
        </Section>

        <Section title="Constraints">
          <div>
            <span className="font-medium text-slate-900">Do not touch</span>
            <div className="mt-1">
              <List items={decision.constraints?.doNotTouch} />
            </div>
          </div>

          <div>
            <span className="font-medium text-slate-900">Must preserve</span>
            <div className="mt-1">
              <List items={decision.constraints?.mustPreserve} />
            </div>
          </div>
        </Section>

        <Section title="Verification">
          <div>
            <span className="font-medium text-slate-900">Success criteria</span>
            <div className="mt-1">
              <List items={decision.verification?.successCriteria} />
            </div>
          </div>

          <div>
            <span className="font-medium text-slate-900">Regression checks</span>
            <div className="mt-1">
              <List items={decision.verification?.regressionChecks} />
            </div>
          </div>
        </Section>
      </div>

      {(decision.uncertainty?.evidenceGaps?.length ||
        decision.uncertainty?.notes) && (
        <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-4">
          <h4 className="mb-2 text-sm font-semibold text-amber-900">
            Uncertainty
          </h4>

          {decision.uncertainty?.evidenceGaps?.length ? (
            <div className="mb-3">
              <div className="mb-1 text-sm font-medium text-amber-900">
                Evidence gaps
              </div>
              <List
                items={decision.uncertainty.evidenceGaps}
                emptyLabel="No evidence gaps"
              />
            </div>
          ) : null}

          {decision.uncertainty?.notes ? (
            <div className="text-sm text-amber-900">
              <span className="font-medium">Notes:</span>{" "}
              {decision.uncertainty.notes}
            </div>
          ) : null}
        </div>
      )}

      <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
        <h4 className="mb-2 text-sm font-semibold text-slate-900">Approval</h4>
        <div className="text-sm text-slate-700">
          <span className="font-medium text-slate-900">Required:</span>{" "}
          {decision.approval?.required ? "Yes" : "No"}
        </div>
        {decision.approval?.reason && (
          <div className="mt-1 text-sm text-slate-700">
            <span className="font-medium text-slate-900">Reason:</span>{" "}
            {decision.approval.reason}
          </div>
        )}
      </div>

      {(decision.decisionId ||
        decision.updatedAt ||
        decision.decisionSource ||
        decision.requestedBy) && (
        <div className="mt-4 border-t border-slate-200 pt-3 text-xs text-slate-500">
          <div className="flex flex-wrap gap-x-4 gap-y-1">
            {decision.decisionId ? (
              <span>
                <span className="font-medium text-slate-700">Decision ID:</span>{" "}
                {decision.decisionId}
              </span>
            ) : null}

            {decision.updatedAt ? (
              <span>
                <span className="font-medium text-slate-700">Updated:</span>{" "}
                {decision.updatedAt}
              </span>
            ) : null}

            {decision.decisionSource ? (
              <span>
                <span className="font-medium text-slate-700">Source:</span>{" "}
                {formatLabel(decision.decisionSource)}
              </span>
            ) : null}

            {decision.requestedBy ? (
              <span>
                <span className="font-medium text-slate-700">Requested by:</span>{" "}
                {decision.requestedBy}
              </span>
            ) : null}
          </div>
        </div>
      )}
    </div>
  );
};

export default PerttiDecisionCard;
