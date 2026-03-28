import React from "react";

import { EvidenceSummaryCard } from "../components/source-detail/EvidenceSummaryCard";
import { PerttiDecisionCard } from "../components/source-detail/PerttiDecisionCard";
import { ExecutionStatusCard } from "../components/source-detail/ExecutionStatusCard";
import { ActionGuardrailsCard } from "../components/source-detail/ActionGuardrailsCard";
import { DecisionHistoryCard } from "../components/source-detail/DecisionHistoryCard";
import { ExecutionHistoryCard } from "../components/source-detail/ExecutionHistoryCard";
import { CaseTimelineCard } from "../components/source-detail/CaseTimelineCard";

import mockDecisionSurface from "../dev/mockDecisionSurface";
import { mockExecutionSurface } from "../dev/mockExecutionSurface";
import mockDecisionHistorySurface from "../dev/mockDecisionHistorySurface";
import mockExecutionHistorySurface from "../dev/mockExecutionHistorySurface";
import mockCaseTimelineSurface from "../dev/mockCaseTimelineSurface";

import {
  SourceDecisionSurface,
  SourceExecutionSurface,
  SourceDecisionHistoryItem,
  SourceExecutionHistoryItem,
  SourceCaseTimelineItem,
} from "../components/source-detail/decisionSurfaceTypes";

/**
 * Phase 2 / 3 / 4 mock toggles
 *
 * Keep all false by default in production-oriented state.
 * These are only for local preview/testing.
 */
const USE_MOCK_DECISION = false;
const USE_MOCK_EXECUTION = false;
const USE_MOCK_HISTORY = false;

const SourceDetailPage: React.FC = () => {
  /**
   * CityOS must not generate decisions internally.
   * If no external decision exists, keep this null.
   */
  const decisionSurface: SourceDecisionSurface | null = USE_MOCK_DECISION
    ? mockDecisionSurface
    : null;

  /**
   * Passive execution surface only.
   * If no execution object exists, keep this null.
   */
  const executionSurface: SourceExecutionSurface | null = USE_MOCK_EXECUTION
    ? mockExecutionSurface
    : null;

  /**
   * Phase 4 history/timeline placeholders.
   * Null-safe and passive.
   */
  const decisionHistory: SourceDecisionHistoryItem[] = USE_MOCK_HISTORY
    ? mockDecisionHistorySurface
    : [];

  const executionHistory: SourceExecutionHistoryItem[] = USE_MOCK_HISTORY
    ? mockExecutionHistorySurface
    : [];

  const caseTimeline: SourceCaseTimelineItem[] = USE_MOCK_HISTORY
    ? mockCaseTimelineSurface
    : [];

  /**
   * These remain placeholders here unless you already have
   * an existing source-detail view model in your project.
   *
   * Replace these later with real read-only source data.
   */
  const evidenceSummary = null;
  const actionGuardrails = null;

  return (
    <div className="mx-auto max-w-7xl space-y-6 px-4 py-6">
      <header className="space-y-1">
        <h1 className="text-2xl font-bold text-slate-900">Source Detail</h1>
        <p className="text-sm text-slate-500">
          Case-level operational view for source evidence, decision, execution,
          history, and deep debug details.
        </p>
      </header>

      {/* 1. Evidence */}
      <EvidenceSummaryCard summary={evidenceSummary} />

      {/* 2. Decision */}
      <PerttiDecisionCard decision={decisionSurface} />

      {/* 3. Execution */}
      <ExecutionStatusCard execution={executionSurface} />

      {/* 4. Guardrails */}
      <ActionGuardrailsCard guardrails={actionGuardrails} />

      {/* 5. Decision History */}
      <DecisionHistoryCard items={decisionHistory} />

      {/* 6. Execution History */}
      <ExecutionHistoryCard items={executionHistory} />

      {/* 7. Case Timeline */}
      <CaseTimelineCard items={caseTimeline} />

      {/* 8. Debug */}
      <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <h3 className="text-lg font-semibold text-slate-900">Debug</h3>
        <p className="mt-2 text-sm text-slate-500">
          Existing deep debug sections remain below the operational summary
          surfaces.
        </p>

        <div className="mt-4 rounded-xl border border-dashed border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
          Keep current source debug panels, analyzer output, candidate sets,
          runtime configuration, and other detailed observability sections here.
        </div>
      </section>
    </div>
  );
};

export default SourceDetailPage;
