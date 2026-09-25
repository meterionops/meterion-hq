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
    assert e.extraction_hash == e.raw_hash
    assert e.extraction_bytes == e.body_bytes


def test_evidence_distinguishes_raw_response_from_rendered_extraction():
    e = build_evidence(
        source_id="s",
        source_url="https://example.com",
        body=b"<html>shell</html>",
        extraction_body=b"<html>shell target</html>",
        collection_method="dynamic_browser",
        rights_status="public_permitted",
        fetched_at="2026-09-24T00:00:00+00:00",
    )
    assert e.raw_hash != e.extraction_hash
    assert e.body_bytes == 18
    assert e.extraction_bytes == 25
