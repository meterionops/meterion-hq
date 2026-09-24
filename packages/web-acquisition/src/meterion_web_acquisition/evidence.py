from __future__ import annotations

import hashlib
from datetime import datetime, timezone

from .models import EvidenceRecord, RightsStatus


def sha256_bytes(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def build_evidence(
    *,
    source_id: str,
    source_url: str,
    body: bytes,
    collection_method: str,
    http_status: int | None = None,
    raw_snapshot_ref: str | None = None,
    extractor_id: str | None = None,
    extractor_version: str | None = None,
    evidence_fragment: str | None = None,
    rights_status: RightsStatus = "unknown",
    response_meta: dict | None = None,
    fetched_at: str | None = None,
) -> EvidenceRecord:
    return EvidenceRecord(
        source_id=source_id,
        source_url=source_url,
        fetched_at=fetched_at or utc_now_iso(),
        collection_method=collection_method,
        http_status=http_status,
        raw_hash=sha256_bytes(body),
        body_bytes=len(body),
        raw_snapshot_ref=raw_snapshot_ref,
        extractor_id=extractor_id,
        extractor_version=extractor_version,
        evidence_fragment=evidence_fragment,
        rights_status=rights_status,
        response_meta=response_meta or {},
    )
