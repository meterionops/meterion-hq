from __future__ import annotations

from dataclasses import asdict
from typing import Any, Mapping, Protocol

from .models import CollectionJob, RoutingDecision, SourceObservation


COLLECTION_STRATEGY_OPTIONS = {
    "api_feed": "Use an official/public API, feed, dataset, sitemap, structured endpoint, or public page XHR endpoint.",
    "static_http": "Use ordinary HTTP extraction from page HTML.",
    "dynamic_browser": "Use JavaScript/browser rendering or XHR capture.",
    "stealth_browser": "Use a more browser-like client only for permitted public content.",
    "research_pause": "Investigate source design/rights further before collecting.",
}

COLLECTION_STRATEGY_INSTRUCTION = (
    "Choose the lowest-cost collection strategy that is likely to produce reliable, "
    "auditable evidence for the requested field under the stated constraints."
)


class JevDecisionProvider(Protocol):
    def choose_collection_strategy(
        self,
        *,
        state: Mapping[str, Any],
        instruction: str,
        criteria: Mapping[str, str],
    ) -> RoutingDecision: ...


def collection_strategy_state(job: CollectionJob, source: SourceObservation) -> dict[str, Any]:
    return {
        "job": asdict(job),
        "source_observation": asdict(source),
        "guardrail": "Jev may choose among explicit routes but may not invent source facts or access rights.",
    }
