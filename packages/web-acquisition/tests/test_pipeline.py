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


def extractor(body, evidence):
    assert body == b"price=14.90"
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


def test_pipeline_keeps_evidence_and_promotes_valid_candidate():
    run = run_acquisition(
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
    )
    assert run.evidence.raw_hash.startswith("sha256:")
    assert run.decisions[0].status == "promote"
