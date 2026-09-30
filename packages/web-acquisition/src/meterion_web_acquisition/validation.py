from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from .models import CandidateObservation, CanonicalDecision, EvidenceRecord


@dataclass(frozen=True)
class ValidationResult:
    ok: bool
    reasons: tuple[str, ...]


def validate_candidate(candidate: CandidateObservation, evidence: Iterable[EvidenceRecord]) -> ValidationResult:
    reasons: list[str] = []
    evidence = tuple(evidence)

    if not candidate.entity_key.strip():
        reasons.append("missing_entity_key")
    if not candidate.field.strip():
        reasons.append("missing_field")
    if not candidate.source_url.startswith(("http://", "https://")):
        reasons.append("invalid_source_url")
    if candidate.confidence is not None and not (0.0 <= candidate.confidence <= 1.0):
        reasons.append("invalid_confidence")

    matching = [e for e in evidence if e.source_url == candidate.source_url]
    if not matching:
        reasons.append("missing_source_evidence")
    if any(e.rights_status == "prohibited" for e in matching):
        reasons.append("prohibited_source")
    elif any(e.rights_status != "public_permitted" for e in matching):
        reasons.append("insufficient_source_rights")

    for key, passed in candidate.validation.items():
        if not passed:
            reasons.append(f"validation_failed:{key}")

    return ValidationResult(ok=not reasons, reasons=tuple(reasons))


def deterministic_decision(candidate: CandidateObservation, evidence: Iterable[EvidenceRecord]) -> CanonicalDecision:
    evidence = tuple(evidence)
    result = validate_candidate(candidate, evidence)
    if not result.ok:
        hard = {"prohibited_source", "missing_entity_key", "missing_field"}
        status = "reject" if hard.intersection(result.reasons) else "review"
        return CanonicalDecision(
            status=status,
            reason=",".join(result.reasons),
            candidate=candidate,
            evidence=evidence,
        )

    required = {"type_ok", "identity_ok", "freshness_ok"}
    if required.issubset(candidate.validation) and all(candidate.validation[k] for k in required):
        return CanonicalDecision(
            status="promote",
            reason="deterministic required checks passed",
            candidate=candidate,
            evidence=evidence,
        )

    return CanonicalDecision(
        status="review",
        reason="deterministic checks are valid but promotion evidence is incomplete",
        candidate=candidate,
        evidence=evidence,
    )
