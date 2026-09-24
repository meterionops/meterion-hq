from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Literal, Mapping, Sequence

CollectionMode = Literal[
    "api_feed",
    "static_http",
    "dynamic_browser",
    "stealth_browser",
    "research_pause",
]

DecisionStatus = Literal[
    "promote",
    "review",
    "reject",
    "repair_adapter",
    "defer_refresh",
]

RightsStatus = Literal[
    "public_permitted",
    "manual_only",
    "unknown",
    "prohibited",
]


@dataclass(frozen=True)
class CollectionJob:
    job_id: str
    project_key: str
    source_url: str
    target: str
    fields: tuple[str, ...] = ()
    geography: str | None = None
    recurring: bool = False
    expected_scale: int | None = None
    freshness_ttl_seconds: int | None = None
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class SourceObservation:
    has_official_api_or_feed: bool = False
    has_public_structured_endpoint: bool = False
    static_html_contains_target: bool = False
    has_public_xhr_endpoint: bool = False
    requires_javascript: bool = False
    ordinary_browser_blocked: bool = False
    rights_status: RightsStatus = "unknown"
    allow_stealth: bool = False
    notes: tuple[str, ...] = ()


@dataclass(frozen=True)
class RoutingDecision:
    mode: CollectionMode
    reason: str
    needs_jev: bool = False
    confidence: float | None = None
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class EvidenceRecord:
    source_id: str
    source_url: str
    fetched_at: str
    collection_method: str
    raw_hash: str
    body_bytes: int
    extraction_hash: str
    extraction_bytes: int
    raw_snapshot_ref: str | None = None
    http_status: int | None = None
    extractor_id: str | None = None
    extractor_version: str | None = None
    evidence_fragment: str | None = None
    rights_status: RightsStatus = "unknown"
    response_meta: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class CandidateObservation:
    entity_key: str
    field: str
    raw_value: Any
    normalized_value: Any
    observed_at: str
    source_id: str
    source_url: str
    confidence: float | None = None
    validation: Mapping[str, bool] = field(default_factory=dict)
    status: Literal["candidate"] = "candidate"
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class CanonicalDecision:
    status: DecisionStatus
    reason: str
    candidate: CandidateObservation | None = None
    evidence: Sequence[EvidenceRecord] = field(default_factory=tuple)
    jev_result: Mapping[str, Any] | None = None


@dataclass(frozen=True)
class SourceProfile:
    source_id: str
    domain: str
    preferred_mode: CollectionMode | None = None
    public_endpoints: tuple[str, ...] = ()
    selectors: Mapping[str, str] = field(default_factory=dict)
    known_failure_modes: tuple[str, ...] = ()
    locale_behavior: Mapping[str, str] = field(default_factory=dict)
    pagination_pattern: str | None = None
    last_successful_collection: str | None = None
    adapter_version: str | None = None
