import React from "react";

type ActionGuardrails = {
  safeActions?: string[];
  approvalRequired?: string[];
  blockedActions?: string[];
  notes?: string[];
};

type Props = {
  guardrails?: ActionGuardrails | null;
};

function formatLabel(value?: string): string {
  if (!value) return "—";
  return value
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function GuardrailList({
  title,
  items,
  tone,
}: {
  title: string;
  items?: string[];
  tone: "safe" | "approval" | "blocked";
}) {
  const toneClasses =
    tone === "safe"
      ? "border-emerald-200 bg-emerald-50"
      : tone === "approval"
        ? "border-amber-200 bg-amber-50"
        : "border-red-200 bg-red-50";

  return (
    <section className={`rounded-xl border p-4 ${toneClasses}`}>
      <h4 className="mb-3 text-sm font-semibold text-slate-900">{title}</h4>

      {!items || items.length === 0 ? (
        <p className="text-sm text-slate-600">None</p>
      ) : (
        <ul className="list-disc space-y-1 pl-5 text-sm text-slate-700">
          {items.map((item, idx) => (
            <li key={`${item}-${idx}`}>{formatLabel(item)}</li>
          ))}
        </ul>
      )}
    </section>
  );
}

function EmptyState() {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-slate-900">Guardrails</h3>
        <p className="mt-1 text-sm text-slate-500">
          What is allowed, what requires approval, and what is blocked.
        </p>
      </div>

      <div className="rounded-xl border border-dashed border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
        No guardrail summary available yet.
      </div>
    </div>
  );
}

export const ActionGuardrailsCard: React.FC<Props> = ({ guardrails }) => {
  if (!guardrails) {
    return <EmptyState />;
  }

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-slate-900">Guardrails</h3>
        <p className="mt-1 text-sm text-slate-500">
          Operational safety boundaries for this source case.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <GuardrailList
          title="Safe Actions"
          items={guardrails.safeActions}
          tone="safe"
        />

        <GuardrailList
          title="Approval Required"
          items={guardrails.approvalRequired}
          tone="approval"
        />

        <GuardrailList
          title="Blocked Actions"
          items={guardrails.blockedActions}
          tone="blocked"
        />
      </div>

      {guardrails.notes && guardrails.notes.length > 0 ? (
        <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
          <h4 className="mb-2 text-sm font-semibold text-slate-900">Notes</h4>
          <ul className="list-disc space-y-1 pl-5 text-sm text-slate-700">
            {guardrails.notes.map((note, idx) => (
              <li key={`${note}-${idx}`}>{note}</li>
            ))}
          </ul>
        </div>
      ) : null}
    </div>
  );
};

export default ActionGuardrailsCard;
