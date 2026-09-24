from meterion_web_acquisition import CollectionJob, SourceObservation, route_collection


def job() -> CollectionJob:
    return CollectionJob(job_id="j1", project_key="maistio", source_url="https://example.com", target="menu")


def test_prefers_structured_endpoint_over_browser():
    d = route_collection(job(), SourceObservation(
        has_public_structured_endpoint=True,
        requires_javascript=True,
        rights_status="public_permitted",
    ))
    assert d.mode == "api_feed"
    assert not d.needs_jev


def test_prefers_public_xhr_over_static_html():
    d = route_collection(job(), SourceObservation(
        has_public_xhr_endpoint=True,
        static_html_contains_target=True,
        rights_status="public_permitted",
    ))
    assert d.mode == "api_feed"


def test_static_before_browser():
    d = route_collection(job(), SourceObservation(
        static_html_contains_target=True,
        requires_javascript=True,
        rights_status="public_permitted",
    ))
    assert d.mode == "static_http"


def test_unknown_rights_pauses():
    d = route_collection(job(), SourceObservation(static_html_contains_target=True))
    assert d.mode == "research_pause"
    assert d.needs_jev


def test_block_does_not_auto_escalate_to_stealth():
    d = route_collection(job(), SourceObservation(
        ordinary_browser_blocked=True,
        rights_status="public_permitted",
        allow_stealth=False,
    ))
    assert d.mode == "research_pause"
    assert d.needs_jev
