import { EvidenceSummary } from "../components/source-detail/decisionSurfaceTypes";

export const mockEvidenceSummary: EvidenceSummary = {
  fetchStatus: "ok",
  eventsFound: 0,
  datesFound: 0,
  mappedEventsFound: 0,
  analyzerConfidence: "0%",
  patternLabel: "js_rendered_suspected",
  patternConfidence: "low",
  candidateSetCount: 1,
  candidateQuality: "low",
  rawHtmlVerdict: "missing",
  renderedDomVerdict: "not_checked",
  notes: [
    "Root fetch succeeded",
    "No extractable dates found",
    "Analyzer output remains signal-level only",
  ],
};

export default mockEvidenceSummary;
