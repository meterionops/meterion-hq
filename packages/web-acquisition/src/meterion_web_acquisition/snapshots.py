"""Explicit local evidence sink. No collection, canonical writes or domain parsing."""
from __future__ import annotations

import json
from pathlib import Path

from .engine import EngineResponse
from .evidence import sha256_bytes, utc_now_iso


def _store(root: Path, body: bytes) -> dict:
    digest = sha256_bytes(body)
    relative = 'blobs/' + digest.split(':', 1)[1] + '.bin'
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        with target.open('xb') as output:
            output.write(body)
    except FileExistsError:
        if target.read_bytes() != body:
            raise ValueError('existing_snapshot_integrity_mismatch')
    if sha256_bytes(target.read_bytes()) != digest:
        raise ValueError('snapshot_write_integrity_mismatch')
    return dict(raw_snapshot_ref=relative, raw_hash=digest, body_bytes=len(body))


def retain_response(response: EngineResponse, root: Path, *, source_identity_url: str,
                    fetched_at: str | None = None) -> dict:
    """Persist exact bytes and a hash-addressed manifest; never pretend gaps are empty.

    Caller owns permission, fetch timestamp, durable storage and retention policy.
    No headers/cookies or raw bytes are copied into the JSON manifest.
    """
    root = Path(root)
    xhr = []
    for item in response.captured_responses:
        row = dict(url=item.url, status=item.status, content_type=item.content_type,
                   body_bytes=item.body_bytes, raw_hash=item.raw_hash,
                   omission_reason=item.omission_reason, raw_snapshot_ref=None)
        if item.body is not None:
            if len(item.body) != item.body_bytes or sha256_bytes(item.body) != item.raw_hash:
                raise ValueError('captured_response_integrity_mismatch')
            row.update(_store(root, item.body))
        xhr.append(row)
    omitted = int(response.metadata.get('captured_xhr_omitted_count', 0))
    declared_count = int(response.metadata.get('captured_xhr_count', len(xhr)))
    manifest = dict(
        version='response-snapshots-v1', source_identity_url=source_identity_url,
        requested_fetch_url=response.metadata.get('requested_fetch_url', source_identity_url),
        collection_method=response.metadata.get('collection_method'),
        final_url=response.final_url, http_status=response.status,
        fetched_at=fetched_at or response.metadata.get('fetched_at') or utc_now_iso(),
        raw_response=_store(root, response.body),
        extraction=_store(root, response.content_for_extraction),
        captured_responses=xhr, captured_xhr_count=declared_count,
        captured_xhr_omitted_count=omitted,
        xhr_evidence_complete=omitted == 0 and declared_count == len(xhr)
            and all(x['raw_snapshot_ref'] is not None for x in xhr),
    )
    raw_manifest = (json.dumps(manifest, sort_keys=True, ensure_ascii=False, indent=2) + '\n').encode()
    saved = _store(root, raw_manifest)
    return dict(manifest_ref=saved['raw_snapshot_ref'], manifest_hash=saved['raw_hash'], **manifest)
