import React from "react";

import { EvidenceSummaryCard } from "../components/source-detail/EvidenceSummaryCard";
import { PerttiDecisionCard } from "../components/source-detail/PerttiDecisionCard";
import { OperatorGuidanceCard } from "../components/source-detail/OperatorGuidanceCard";
import { ExecutionStatusCard } from "../components/source-detail/ExecutionStatusCard";
import { ActionGuardrailsCard } from "../components/source-detail/ActionGuardrailsCard";
import { DecisionHistoryCard } from "../components/source-detail/DecisionHistoryCard";
import { ExecutionHistoryCard } from "../components/source-detail/ExecutionHistoryCard";
import { CaseTimelineCard } from "../components/source-detail/CaseTimelineCard";

import mockEvidenceSummary from "../dev/mockEvidenceSummary";
import mockActionGuardrails from "../dev/mockActionGuardrails";
import mockDecisionSurface from "../dev/mockDecisionSurface";
import { mockOperatorGuidance } from "../dev/mockOperatorGuidance";
import { mockExecutionSurface } from "../dev/mockExecutionSurface";
import mockDecisionHistorySurface from "../dev/mockDecisionHistorySurface";
import mockExecutionHistorySurface from "../dev/mockExecutionHistorySurface";
import mockCaseTimelineSurface from "../dev/mockCaseTimelineSurface";

import type {
  EvidenceSummary,
  ActionGuardrails,
  SourceDecisionSurface,
  SourceExecutionSurface,
  SourceDecisionHistoryItem,
  SourceExecutionHistoryItem,
  SourceCaseTimelineItem,
  OperatorGuidance,
} from "../components/source-detail/decisionSurfaceTypes";

/**
 * Local preview toggles only.
 * Keep false by default for a production-safe passive host state.
 */
const USE_MOCK_EVIDENCE = true;
const USE_MOCK_GUARDRAILS = true;
const USE_MOCK_DECISION = false;
const USE_MOCK_GUIDANCE = true;
const USE_MOCK_EXECUTION = false;
const USE_MOCK_HISTORY = false;

const SourceDetailPage: React.FC = () => {
  /**
   * CityOS must not generate decisions internally.
   * Null means no external/injected surface is available yet.
   */
  const evidenceSummary: EvidenceSummary | null = USE_MOCK_EVIDENCE
    ? mockEvidenceSummary
    : null;

  const actionGuardrails: ActionGuardrails | null = USE_MOCK_GUARDRAILS
    ? mockActionGuardrails
    : null;

  const decisionSurface: SourceDecisionSurface | null = USE_MOCK_DECISION
    ? mockDecisionSurface
    : null;

  const operatorGuidance: OperatorGuidance | null = USE_MOCK_GUIDANCE
    ? mockOperatorGuidance
    : null;

  const executionSurface: SourceExecutionSurface | null = USE_MOCK_EXECUTION
    ? mockExecutionSurface
    : null;

  const decisionHistory: SourceDecisionHistoryItem[] = USE_MOCK_HISTORY
    ? mockDecisionHistorySurface
    : [];

  const executionHistory: SourceExecutionHistoryItem[] = USE_MOCK_HISTORY
    ? mockExecutionHistorySurface
    : [];

  const caseTimeline: SourceCaseTimelineItem[] = USE_MOCK_HISTORY
    ? mockCaseTimelineSurface
    : [];

  return (
    <div className="mx-auto max-w-7xl space-y-6 px-4 py-6">
      <header className="space-y-1">
        <h1 className="text-2xl font-bold text-slate-900">Source Detail</h1>
        <p className="text-sm text-slate-500">
          Case-level operational view for source evidence, decision, guidance,
          execution, history, and deep debug details.
        </p>
      </header>

      {/* 1. Evidence */}
      <EvidenceSummaryCard summary={evidenceSummary} />

      {/* 2. Decision */}
      <PerttiDecisionCard decision={decisionSurface} />

      {/* 3. Operator Guidance */}
      <OperatorGuidanceCard guidance={operatorGuidance} />

      {/* 4. Execution */}
      <ExecutionStatusCard execution={executionSurface} />

      {/* 5. Guardrails */}
      <ActionGuardrailsCard guardrails={actionGuardrails} />

      {/* 6. Decision History */}
      <DecisionHistoryCard items={decisionHistory} />

      {/* 7. Execution History */}
      <ExecutionHistoryCard items={executionHistory} />

      {/* 8. Case Timeline */}
      <CaseTimelineCard items={caseTimeline} />

      {/* 9. Debug */}
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
