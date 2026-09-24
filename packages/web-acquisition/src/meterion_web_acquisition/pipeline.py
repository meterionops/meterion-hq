from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Iterable

from .engine import CollectionEngine, EngineRequest
from .evidence import build_evidence
from .models import CandidateObservation, CanonicalDecision, CollectionJob, EvidenceRecord, RoutingDecision
from .validation import deterministic_decision

Extractor = Callable[[bytes, EvidenceRecord], Iterable[CandidateObservation]]


@dataclass(frozen=True)
class AcquisitionRun:
    job: CollectionJob
    routing: RoutingDecision
    evidence: EvidenceRecord
    candidates: tuple[CandidateObservation, ...]
    decisions: tuple[CanonicalDecision, ...]


def run_acquisition(
    *,
    job: CollectionJob,
    routing: RoutingDecision,
    engine: CollectionEngine,
    extractor: Extractor,
    source_id: str,
    rights_status: str = "public_permitted",
    snapshot_ref: str | None = None,
) -> AcquisitionRun:
    if routing.mode == "research_pause":
        raise ValueError("research_pause is not an executable collection route")

    response = engine.collect(EngineRequest(url=job.source_url, mode=routing.mode))
    evidence = build_evidence(
        source_id=source_id,
        source_url=response.final_url,
        body=response.body,
        collection_method=routing.mode,
        http_status=response.status,
        raw_snapshot_ref=snapshot_ref,
        rights_status=rights_status,  # type: ignore[arg-type]
        response_meta=dict(response.metadata),
    )
    candidates = tuple(extractor(response.body, evidence))
    decisions = tuple(deterministic_decision(c, (evidence,)) for c in candidates)
    return AcquisitionRun(
        job=job,
        routing=routing,
        evidence=evidence,
        candidates=candidates,
        decisions=decisions,
    )
