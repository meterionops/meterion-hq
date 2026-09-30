from meterion_web_acquisition import (
    CollectionJob,
    SourceObservation,
    SourceProfile,
    route_collection,
    source_observation_from_profile,
)


def job() -> CollectionJob:
    return CollectionJob(job_id="j1", project_key="maistio", source_url="https://example.com/menu", target="menu")


def test_prefers_structured_endpoint_over_browser():
    d = route_collection(job(), SourceObservation(
        has_public_structured_endpoint=True,
        requires_javascript=True,
        rights_status="public_permitted",
        preferred_fetch_url="https://example.com/api/menu",
    ))
    assert d.mode == "api_feed"
    assert d.fetch_url == "https://example.com/api/menu"
    assert not d.needs_jev


def test_prefers_public_xhr_over_static_html():
    d = route_collection(job(), SourceObservation(
        has_public_xhr_endpoint=True,
        static_html_contains_target=True,
        rights_status="public_permitted",
        preferred_fetch_url="https://example.com/xhr/menu",
    ))
    assert d.mode == "api_feed"
    assert d.fetch_url == "https://example.com/xhr/menu"


def test_static_before_browser():
    d = route_collection(job(), SourceObservation(
        static_html_contains_target=True,
        requires_javascript=True,
        rights_status="public_permitted",
    ))
    assert d.mode == "static_http"
    assert d.fetch_url == job().source_url


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


def test_verified_api_profile_uses_only_its_verified_endpoint():
    profile = SourceProfile(
        source_id="menu-source-1",
        domain="example.com",
        preferred_mode="api_feed",
        public_endpoints=("https://example.com/wp-json/wp/v2/pages/10",),
    )
    observation = source_observation_from_profile(profile, rights_status="public_permitted")
    decision = route_collection(job(), observation)
    assert decision.mode == "api_feed"
    assert decision.fetch_url == "https://example.com/wp-json/wp/v2/pages/10"


def test_api_profile_without_verified_endpoint_fails_closed():
    profile = SourceProfile(
        source_id="menu-source-1",
        domain="example.com",
        preferred_mode="api_feed",
    )
    observation = source_observation_from_profile(profile, rights_status="public_permitted")
    decision = route_collection(job(), observation)
    assert decision.mode == "research_pause"
    assert decision.needs_jev
