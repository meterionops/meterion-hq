from meterion_web_acquisition import (
    CandidateObservation,
    CollectionJob,
    EngineResponse,
    RoutingDecision,
    run_acquisition,
)


class FakeEngine:
    name = "fake"

    def collect(self, request):
        return EngineResponse(body=b"price=14.90", status=200, final_url=request.url)


class FakeDynamicEngine:
    name = "fake-dynamic"

    def collect(self, request):
        return EngineResponse(
            body=b"<html>shell</html>",
            extraction_body=b"<html>shell price=14.90</html>",
            status=200,
            final_url=request.url,
        )


def extractor(body, evidence):
    assert b"price=14.90" in body
    yield CandidateObservation(
        entity_key="restaurant:1",
        field="price",
        raw_value="14.90",
        normalized_value=14.90,
        observed_at=evidence.fetched_at,
        source_id=evidence.source_id,
        source_url=evidence.source_url,
        confidence=0.99,
        validation={"type_ok": True, "identity_ok": True, "freshness_ok": True},
    )


def make_run(**kwargs):
    return run_acquisition(
        job=CollectionJob(
            job_id="j1",
            project_key="maistio",
            source_url="https://example.com/menu",
            target="menu",
            fields=("price",),
        ),
        routing=RoutingDecision(mode="static_http", reason="test"),
        engine=FakeEngine(),
        extractor=extractor,
        source_id="restaurant-own-site",
        **kwargs,
    )


def test_pipeline_keeps_evidence_and_promotes_valid_candidate():
    run = make_run(rights_status="public_permitted")
    assert run.evidence.raw_hash.startswith("sha256:")
    assert run.evidence.extraction_hash == run.evidence.raw_hash
    assert run.decisions[0].status == "promote"


def test_pipeline_fails_closed_when_rights_are_not_supplied():
    run = make_run()
    assert run.evidence.rights_status == "unknown"
    assert run.decisions[0].status == "review"
    assert "insufficient_source_rights" in run.decisions[0].reason


def test_pipeline_extracts_from_rendered_content_but_retains_raw_evidence():
    run = run_acquisition(
        job=CollectionJob(
            job_id="j2",
            project_key="maistio",
            source_url="https://example.com/dynamic-menu",
            target="menu",
        ),
        routing=RoutingDecision(mode="dynamic_browser", reason="test"),
        engine=FakeDynamicEngine(),
        extractor=extractor,
        source_id="restaurant-own-site",
        rights_status="public_permitted",
    )
    assert run.evidence.raw_hash != run.evidence.extraction_hash
    assert run.evidence.body_bytes < run.evidence.extraction_bytes
    assert run.decisions[0].status == "promote"


def test_pipeline_preserves_source_identity_when_fetching_verified_endpoint():
    run = run_acquisition(
        job=CollectionJob(
            job_id="j3",
            project_key="maistio",
            source_url="https://example.com/menu",
            target="menu",
        ),
        routing=RoutingDecision(
            mode="api_feed",
            reason="verified endpoint",
            fetch_url="https://example.com/wp-json/wp/v2/pages/10",
        ),
        engine=FakeEngine(),
        extractor=extractor,
        source_id="restaurant-own-site",
        rights_status="public_permitted",
    )
    assert run.evidence.source_url == "https://example.com/wp-json/wp/v2/pages/10"
    assert run.evidence.response_meta["source_identity_url"] == "https://example.com/menu"
    assert run.evidence.response_meta["requested_fetch_url"] == "https://example.com/wp-json/wp/v2/pages/10"
