from types import SimpleNamespace
import json
import pytest

from meterion_web_acquisition.engine import EngineResponse
from meterion_web_acquisition.engines.scrapling_engine import capture_responses
from meterion_web_acquisition.evidence import sha256_bytes
from meterion_web_acquisition.snapshots import retain_response


def xhr(body=b'{"menu":"test"}', url='https://example.test/data'):
    return SimpleNamespace(body=body, url=url, status=200, headers={'Content-Type':'application/json'})


def response(items, **metadata):
    return EngineResponse(body=b'<html>shell</html>', extraction_body=b'<html>rendered</html>',
        status=200, final_url='https://example.test/', captured_responses=items, metadata=metadata)


def test_exact_bytes_roundtrip_including_empty_binary_and_duplicates(tmp_path):
    bodies = [b'', b'\x00\xff\x80', b'[{"price":15}]', b'[{"price":15}]']
    result = retain_response(response(capture_responses([xhr(b) for b in bodies], True)), tmp_path,
        source_identity_url='https://example.test/', fetched_at='2026-09-25T00:00:00Z')
    assert result['xhr_evidence_complete']
    for entry, body in zip(result['captured_responses'], bodies):
        assert (tmp_path / entry['raw_snapshot_ref']).read_bytes() == body
        assert entry['raw_hash'] == sha256_bytes(body)
    assert result['captured_responses'][2]['raw_snapshot_ref'] == result['captured_responses'][3]['raw_snapshot_ref']
    manifest = json.loads((tmp_path / result['manifest_ref']).read_bytes())
    assert manifest['raw_response']['raw_hash'] != manifest['extraction']['raw_hash']


def test_unavailable_is_distinct_from_empty_and_disabled(tmp_path):
    items = capture_responses([xhr(None), xhr(b'')], True)
    assert items[0].omission_reason == 'body_unavailable'
    assert items[0].raw_hash is None
    assert items[1].body == b''
    result = retain_response(response(items), tmp_path, source_identity_url='https://example.test/')
    assert not result['xhr_evidence_complete']
    assert capture_responses([xhr()], False)[0].omission_reason == 'retention_not_requested'


def test_bounds_report_missing_evidence(monkeypatch, tmp_path):
    from meterion_web_acquisition.engines import scrapling_engine as mod
    monkeypatch.setattr(mod, 'MAX_XHR_BODY_BYTES', 4)
    monkeypatch.setattr(mod, 'MAX_XHR_TOTAL_BYTES', 5)
    items = capture_responses([xhr(b'12345'), xhr(b'1234'), xhr(b'12')], True)
    assert [x.omission_reason for x in items] == ['body_size_limit', None, 'total_size_limit']
    result = retain_response(response(items, captured_xhr_count=4, captured_xhr_omitted_count=1), tmp_path,
        source_identity_url='https://example.test/')
    assert not result['xhr_evidence_complete']


def test_existing_snapshot_tampering_fails_closed(tmp_path):
    r = response(capture_responses([xhr()], True))
    saved = retain_response(r, tmp_path, source_identity_url='https://example.test/')
    (tmp_path / saved['captured_responses'][0]['raw_snapshot_ref']).write_bytes(b'corrupt')
    with pytest.raises(ValueError, match='integrity'):
        retain_response(r, tmp_path, source_identity_url='https://example.test/')


def test_manifest_retains_separate_observations(tmp_path):
    r = response(capture_responses([xhr()], True))
    a = retain_response(r, tmp_path, source_identity_url='https://example.test/', fetched_at='a')
    b = retain_response(r, tmp_path, source_identity_url='https://example.test/', fetched_at='b')
    assert a['manifest_ref'] != b['manifest_ref']
    assert a['captured_responses'] == b['captured_responses']


def test_retention_requires_explicit_pattern_before_collection():
    from meterion_web_acquisition.engine import EngineRequest
    from meterion_web_acquisition.engines.scrapling_engine import ScraplingEngine
    with pytest.raises(ValueError, match='explicit capture pattern'):
        ScraplingEngine().collect(EngineRequest(url='https://example.test', mode='dynamic_browser', retain_xhr_bodies=True))


def test_capture_count_cap_is_explicit():
    assert len(capture_responses([xhr()] * 101, True)) == 100


def test_fetch_identity_and_timestamp_are_preserved(tmp_path):
    result = retain_response(response((), requested_fetch_url='https://example.test/api',
        fetched_at='2026-09-25T01:02:03Z', collection_method='dynamic_browser'), tmp_path,
        source_identity_url='https://example.test/menu')
    assert result['source_identity_url'].endswith('/menu')
    assert result['requested_fetch_url'].endswith('/api')
    assert result['fetched_at'] == '2026-09-25T01:02:03Z'
