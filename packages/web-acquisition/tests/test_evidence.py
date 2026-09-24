from meterion_web_acquisition import build_evidence, sha256_bytes


def test_evidence_hash_and_size_are_stable():
    body = b"hello"
    e = build_evidence(
        source_id="s",
        source_url="https://example.com",
        body=body,
        collection_method="static_http",
        rights_status="public_permitted",
        fetched_at="2026-09-24T00:00:00+00:00",
    )
    assert e.raw_hash == sha256_bytes(body)
    assert e.raw_hash.startswith("sha256:")
    assert e.body_bytes == 5
