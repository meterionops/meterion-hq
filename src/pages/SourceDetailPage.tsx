import React, { useCallback, useEffect, useMemo, useState } from "react";
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
 * Local preview toggles only.
 * Keep these conservative until real data wiring is ready.
 */
const USE_MOCK_EVIDENCE = true;
const USE_MOCK_GUARDRAILS = true;
const USE_MOCK_DECISION = false;
const USE_MOCK_GUIDANCE = true;
const USE_MOCK_EXECUTION = false;
const USE_MOCK_HISTORY = false;
const ENABLE_TEST_DECISION_INJECTION = true;

const ADVISORY_BANNERS: Record<string, string> = {
  missing_city: "Pertti: tämä lähde on ilman kaupunkia",
  city_inactive: "Pertti: tämän kaupungin lähteet eivät ole aktiivisia",
  no_sources: "Pertti: tällä kaupungilla ei ole aktiivisia lähteitä",
};

const SourceDetailPage: React.FC = () => {
  const [searchParams] = useSearchParams();

  // Real route shape: /admin/sources/detail?id=...&from_advisory=...
  const sourceId = searchParams.get("id") || "";
  const fromAdvisory = searchParams.get("from_advisory");

  const adminSecret =
    typeof window !== "undefined"
      ? window.localStorage.getItem("CITYOS_ADMIN_SECRET")
      : null;

  const [persistedDecision, setPersistedDecision] =
    useState<SourceDecisionSurface | null>(null);
  const [decisionLoading, setDecisionLoading] = useState(false);
  const [injecting, setInjecting] = useState(false);
  const [injectError, setInjectError] = useState<string | null>(null);

  /**
   * Phase 1–4 host surfaces.
   * CityOS must not generate decisions internally.
   */
  const evidenceSummary: EvidenceSummary | null = USE_MOCK_EVIDENCE
    ? mockEvidenceSummary
    : null;

  const actionGuardrails: ActionGuardrails | null = USE_MOCK_GUARDRAILS
    ? mockActionGuardrails
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

  const advisoryBanner = useMemo(() => {
    if (!fromAdvisory) return null;
    const text = ADVISORY_BANNERS[fromAdvisory];
    if (!text) return null;

    return (
      <div className="rounded-lg border border-sky-200 bg-sky-50 px-4 py-3 text-sm text-sky-800">
        {text}
      </div>
    );
  }, [fromAdvisory]);

  const refetchDecisionSurface = useCallback(async () => {
    if (!sourceId || !adminSecret) {
      setPersistedDecision(null);
      return;
    }

    try {
      setDecisionLoading(true);
      setInjectError(null);

      const result = await cityosFetch({
        adminSecret,
        action: "get_source_decision_surface",
        payload: {
          source_id: sourceId,
        },
      });

      const decision =
        result?.decision_json ??
        result?.decision ??
        result?.data?.decision_json ??
        null;

      setPersistedDecision(decision);
    } catch (error) {
      console.error("Failed to fetch decision surface", error);
      setPersistedDecision(null);
    } finally {
      setDecisionLoading(false);
    }
  }, [sourceId, adminSecret]);

  useEffect(() => {
    void refetchDecisionSurface();
  }, [refetchDecisionSurface]);

  const decisionSurface: SourceDecisionSurface | null =
    persistedDecision ?? (USE_MOCK_DECISION ? mockDecisionSurface : null);

  const injectTestDecision = async () => {
    if (!sourceId || !adminSecret) return;

    try {
      setInjecting(true);
      setInjectError(null);

      await cityosFetch({
        adminSecret,
        action: "upsert_source_decision_surface",
        payload: {
          source_id: sourceId,
          decision_json: {
            status: "proposed",
            decisionId: `test-${sourceId}`,
            updatedAt: new Date().toISOString(),
            decisionSource: "external",
            requestedBy: "ui-test",
            diagnosis: {
              primaryHypothesis: "rendering_not_confirmed",
              secondaryHypothesis: "parser_mismatch",
              confidence: "medium",
              rationaleSummary:
                "Current evidence does not yet distinguish missing rendered content from parsing failure.",
            },
            nextStep: {
              actionType: "investigate_rendering",
              actionLabel: "check_html_vs_js",
              executor: "openclaw",
              whyThisNow: "Highest information gain with minimal system risk.",
            },
            constraints: {
              doNotTouch: ["parser", "runner", "global configs"],
              mustPreserve: ["audit_trail", "source_local_scope"],
            },
            verification: {
              successCriteria: ["HTML vs DOM verdict produced"],
              regressionChecks: ["no config mutation", "no runner mutation"],
            },
            approval: {
              required: false,
              reason: "Investigation only",
            },
            uncertainty: {
              evidenceGaps: [
                "raw_html_verdict_missing",
                "rendered_dom_verdict_missing",
              ],
              notes: "JS rendering remains unconfirmed.",
            },
          },
          decision_status: "proposed",
          source: "external",
          updated_by: "ui-test",
        },
      });

      await refetchDecisionSurface();
    } catch (error) {
      console.error("Failed to inject test decision", error);
      setInjectError("Failed to inject test decision.");
    } finally {
      setInjecting(false);
    }
  };

  const clearDecision = async () => {
    if (!sourceId || !adminSecret) return;

    try {
      setInjecting(true);
      setInjectError(null);

      await cityosFetch({
        adminSecret,
        action: "upsert_source_decision_surface",
        payload: {
          source_id: sourceId,
          decision_json: null,
          decision_status: "none",
          source: "external",
          updated_by: "ui-test-clear",
        },
      });

      await refetchDecisionSurface();
    } catch (error) {
      console.error("Failed to clear decision", error);
      setInjectError("Failed to clear injected decision.");
    } finally {
      setInjecting(false);
    }
  };

  return (
    <div className="mx-auto max-w-7xl space-y-6 px-4 py-6">
      <header className="space-y-3">
        {advisoryBanner}

        <div className="space-y-1">
          <h1 className="text-2xl font-bold text-slate-900">Source Detail</h1>
          <p className="text-sm text-slate-500">
            Case-level operational view for source evidence, decision, guidance,
            execution, history, and deep debug details.
          </p>
          <p className="text-xs text-slate-400">
            Source ID: {sourceId || "missing"}
          </p>
        </div>
      </header>

      {!adminSecret ? (
        <>
          <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            Aseta admin secret
          </div>

          <EvidenceSummaryCard summary={evidenceSummary} />
          <PerttiDecisionCard decision={decisionSurface} />
          <OperatorGuidanceCard guidance={operatorGuidance} />
          <ExecutionStatusCard execution={executionSurface} />
          <ActionGuardrailsCard guardrails={actionGuardrails} />
          <DecisionHistoryCard items={decisionHistory} />
          <ExecutionHistoryCard items={executionHistory} />
          <CaseTimelineCard items={caseTimeline} />
        </>
      ) : (
        <>
          {ENABLE_TEST_DECISION_INJECTION ? (
            <div className="space-y-2">
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={injectTestDecision}
                  disabled={injecting || decisionLoading || !sourceId}
                  className="text-xs text-slate-500 hover:text-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {injecting ? "Injecting..." : "Inject test decision"}
                </button>

                {persistedDecision ? (
                  <button
                    type="button"
                    onClick={clearDecision}
                    disabled={injecting || decisionLoading || !sourceId}
                    className="text-xs text-slate-400 hover:text-red-600 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Clear
                  </button>
                ) : null}

                {decisionLoading ? (
                  <span className="text-xs text-slate-400">Refreshing…</span>
                ) : null}
              </div>

              {injectError ? (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
                  {injectError}
                </div>
              ) : null}
            </div>
          ) : null}

          <EvidenceSummaryCard summary={evidenceSummary} />
          <PerttiDecisionCard decision={decisionSurface} />
          <OperatorGuidanceCard guidance={operatorGuidance} />
          <ExecutionStatusCard execution={executionSurface} />
          <ActionGuardrailsCard guardrails={actionGuardrails} />
          <DecisionHistoryCard items={decisionHistory} />
          <ExecutionHistoryCard items={executionHistory} />
          <CaseTimelineCard items={caseTimeline} />
        </>
      )}

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
