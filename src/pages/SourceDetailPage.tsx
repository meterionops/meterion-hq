import React, { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";

import { EvidenceSummaryCard } from "../components/source-detail/EvidenceSummaryCard";
import { PerttiDecisionCard } from "../components/source-detail/PerttiDecisionCard";
import { OperatorGuidanceCard } from "../components/source-detail/OperatorGuidanceCard";
import { ExecutionStatusCard } from "../components/source-detail/ExecutionStatusCard";
import { ActionGuardrailsCard } from "../components/source-detail/ActionGuardrailsCard";
import { DecisionHistoryCard } from "../components/source-detail/DecisionHistoryCard";
import { ExecutionHistoryCard } from "../components/source-detail/ExecutionHistoryCard";
import { CaseTimelineCard } from "../components/source-detail/CaseTimelineCard";

import {
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
 * SourceDetailPage
 * - Single source of truth for /admin/sources/detail
 * - Uses query params (?id=, ?from_advisory=)
 * - Safe, deterministic rendering
 */

const SourceDetailPage: React.FC = () => {
  const [searchParams] = useSearchParams();

  // ✅ Query params (correct)
  const sourceId = searchParams.get("id") || "";
  const fromAdvisory = searchParams.get("from_advisory");

  const adminSecret =
    typeof window !== "undefined"
      ? window.localStorage.getItem("CITYOS_ADMIN_SECRET")
      : null;

  const [decision, setDecision] = useState<SourceDecisionSurface | null>(null);
  const [loading, setLoading] = useState(false);

  /**
   * Fetch decision surface
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
        console.error("Failed to fetch decision surface", e);
      } finally {
        setLoading(false);
      }
    };

    run();
  }, [sourceId, adminSecret]);

  /**
   * Advisory banner (pure + deterministic)
   */
  const advisoryBanner = useMemo(() => {
    if (!fromAdvisory) return null;

    const messages: Record<string, string> = {
      missing_city: "Pertti: tämä lähde on ilman kaupunkia",
      city_inactive: "Pertti: tämän kaupungin lähteet eivät ole aktiivisia",
      no_sources: "Pertti: tällä kaupungilla ei ole aktiivisia lähteitä",
    };

    const text = messages[fromAdvisory];
    if (!text) return null;

    return (
      <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3 text-sm text-blue-800">
        {text}
      </div>
    );
  }, [fromAdvisory]);

  /**
   * Mock placeholders (safe fallback)
   * → nämä voi myöhemmin korvata oikealla datalla
   */
  const evidence: EvidenceSummary | null = null;
  const guardrails: ActionGuardrails | null = null;
  const guidance: OperatorGuidance | null = null;
  const execution: SourceExecutionSurface | null = null;
  const decisionHistory: SourceDecisionHistoryItem[] = [];
  const executionHistory: SourceExecutionHistoryItem[] = [];
  const timeline: SourceCaseTimelineItem[] = [];

  return (
    <div className="mx-auto max-w-7xl space-y-6 px-4 py-6">
      {/* HEADER */}
      <header className="space-y-3">
        {advisoryBanner}

        <h1 className="text-2xl font-bold text-slate-900">
          Source Detail
        </h1>

        <p className="text-sm text-slate-500">
          Source ID: {sourceId || "missing"}
        </p>
      </header>

      {/* STATE */}
      {!adminSecret && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Aseta admin secret
        </div>
      )}

      {loading && (
        <div className="text-sm text-slate-400">Loading…</div>
      )}

      {/* CONTENT */}
      <EvidenceSummaryCard summary={evidence} />

      <PerttiDecisionCard decision={decision} />

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
