import React, { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";

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

import { cityosFetch } from "../lib/cityosFetch";

/**
 * Config
 */
const USE_MOCKS = true;

const SourceDetailPage: React.FC = () => {
  const [searchParams] = useSearchParams();

  // ✅ OIKEIN: id query param
  const sourceId = searchParams.get("id") || "";

  // ✅ Pertti context
  const fromAdvisory = searchParams.get("from_advisory");

  const adminSecret =
    typeof window !== "undefined"
      ? window.localStorage.getItem("CITYOS_ADMIN_SECRET")
      : null;

  const [decision, setDecision] = useState<SourceDecisionSurface | null>(null);
  const [loading, setLoading] = useState(false);

  /**
   * FETCH decision surface
   */
  useEffect(() => {
    if (!sourceId || !adminSecret) return;

    const run = async () => {
      try {
        setLoading(true);

        const result = await cityosFetch({
          adminSecret,
          action: "get_source_decision_surface",
          payload: { source_id: sourceId },
        });

        const data =
          result?.decision_json ??
          result?.decision ??
          result?.data?.decision_json ??
          null;

        setDecision(data);
      } catch (e) {
        console.error("decision fetch failed", e);
      } finally {
        setLoading(false);
      }
    };

    run();
  }, [sourceId, adminSecret]);

  /**
   * MOCK / fallback data
   */
  const evidence: EvidenceSummary | null = USE_MOCKS
    ? mockEvidenceSummary
    : null;

  const guardrails: ActionGuardrails | null = USE_MOCKS
    ? mockActionGuardrails
    : null;

  const guidance: OperatorGuidance | null = USE_MOCKS
    ? mockOperatorGuidance
    : null;

  const execution: SourceExecutionSurface | null = USE_MOCKS
    ? mockExecutionSurface
    : null;

  const decisionHistory: SourceDecisionHistoryItem[] = USE_MOCKS
    ? mockDecisionHistorySurface
    : [];

  const executionHistory: SourceExecutionHistoryItem[] = USE_MOCKS
    ? mockExecutionHistorySurface
    : [];

  const timeline: SourceCaseTimelineItem[] = USE_MOCKS
    ? mockCaseTimelineSurface
    : [];

  /**
   * ✅ BANNER — ALWAYS VISIBLE
   */
  const advisoryBanner = (() => {
    if (!fromAdvisory) return null;

    const map: Record<string, string> = {
      missing_city: "Pertti: tämä lähde on ilman kaupunkia",
      city_inactive: "Pertti: tämä kaupunki ei ole aktiivinen",
      no_sources: "Pertti: tällä kaupungilla ei ole lähteitä",
    };

    const text = map[fromAdvisory];
    if (!text) return null;

    return (
      <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800">
        {text}
      </div>
    );
  })();

  /**
   * RENDER
   */
  return (
    <div className="mx-auto max-w-7xl space-y-6 px-4 py-6">
      {/* ✅ HEADER + BANNER */}
      <header className="space-y-3">
        {advisoryBanner}

        <h1 className="text-2xl font-bold text-slate-900">
          Source Detail
        </h1>

        <p className="text-sm text-slate-500">
          Source ID: {sourceId || "missing"}
        </p>
      </header>

      {/* LOADING */}
      {loading && (
        <div className="text-sm text-slate-400">Loading…</div>
      )}

      {/* DATA */}
      {!adminSecret && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Aseta admin secret
        </div>
      )}

      {/* CONTENT */}
      <EvidenceSummaryCard summary={evidence} />

      <PerttiDecisionCard decision={decision ?? mockDecisionSurface} />

      <OperatorGuidanceCard guidance={guidance} />

      <ExecutionStatusCard execution={execution} />

      <ActionGuardrailsCard guardrails={guardrails} />

      <DecisionHistoryCard items={decisionHistory} />

      <ExecutionHistoryCard items={executionHistory} />

      <CaseTimelineCard items={timeline} />
    </div>
  );
};

export default SourceDetailPage;
