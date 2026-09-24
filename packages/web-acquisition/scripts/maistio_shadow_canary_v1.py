from __future__ import annotations

import json

from meterion_web_acquisition import (
    CollectionJob,
    EngineRequest,
    SourceObservation,
    build_evidence,
    route_collection,
)
from meterion_web_acquisition.engines.scrapling_engine import ScraplingEngine


SOURCES = [
    {
        "key": "static_mantra_menu",
        "url": "https://www.ravintolamantra.fi/menu",
        "target": "menu",
        "expected_mode": "static_http",
        "observation": {
            "static_html_contains_target": True,
            "rights_status": "public_permitted",
        },
        "required_token": "TOM YUM",
    },
    {
        "key": "structured_rodeo_menu",
        "url": "https://www.rodeosteakhouse.fi/wp-json/wp/v2/pages/319",
        "target": "menu",
        "expected_mode": "api_feed",
        "observation": {
            "has_public_structured_endpoint": True,
            "rights_status": "public_permitted",
        },
        "required_token": "Rodeo",
    },
    {
        "key": "dynamic_one_pint_beer_menu",
        "url": "https://www.onepintpub.com/beer-menu",
        "target": "menu",
        "expected_mode": "dynamic_browser",
        "observation": {
            "requires_javascript": True,
            "rights_status": "public_permitted",
        },
        "compare_static_baseline": True,
        "capture_xhr": ".*",
        "wait_ms": 2500,
    },
]


def content_type(headers: dict) -> str | None:
    for key, value in headers.items():
        if str(key).lower() == "content-type":
            return str(value)
    return None


def result_for_response(source: dict, decision, response, evidence) -> dict:
    headers = dict(response.metadata.get("response_headers", {}) or {})
    text_length = int(response.metadata.get("response_text_length", 0) or 0)
    decoded = response.body.decode("utf-8", errors="ignore")
    token = source.get("required_token")
    return {
        "key": source["key"],
        "requested_url": source["url"],
        "final_url": response.final_url,
        "route": decision.mode,
        "route_reason": decision.reason,
        "status": response.status,
        "content_type": content_type(headers),
        "body_bytes": evidence.body_bytes,
        "raw_hash": evidence.raw_hash,
        "text_length": text_length,
        "redirect_count": int(response.metadata.get("redirect_count", 0) or 0),
        "captured_xhr_count": int(response.metadata.get("captured_xhr_count", 0) or 0),
        "captured_xhr_summaries": list(
            response.metadata.get("captured_xhr_summaries", []) or []
        )[:30],
        "rights_status": evidence.rights_status,
        "required_token": token,
        "required_token_found": None if not token else token.lower() in decoded.lower(),
    }


def main() -> None:
    engine = ScraplingEngine()
    results: list[dict] = []

    for source in SOURCES:
        job = CollectionJob(
            job_id=f"maistio-shadow-{source['key']}",
            project_key="maistio",
            source_url=source["url"],
            target=source["target"],
            recurring=False,
        )
        observation = SourceObservation(**source["observation"])
        decision = route_collection(job, observation)
        if decision.mode != source["expected_mode"]:
            raise AssertionError(
                f"{source['key']}: expected {source['expected_mode']}, got {decision.mode}"
            )

        response = engine.collect(
            EngineRequest(
                url=source["url"],
                mode=decision.mode,
                timeout_ms=30_000,
                wait_ms=int(source.get("wait_ms", 0)),
                network_idle=False,
                disable_resources=False,
                capture_xhr_pattern=source.get("capture_xhr"),
            )
        )
        evidence = build_evidence(
            source_id=f"maistio-shadow:{source['key']}",
            source_url=response.final_url,
            body=response.body,
            collection_method=decision.mode,
            http_status=response.status,
            rights_status="public_permitted",
            response_meta=dict(response.metadata),
        )
        result = result_for_response(source, decision, response, evidence)

        if response.status is None or not (200 <= response.status < 300):
            result["pass"] = False
            result["failure"] = "non_2xx_status"
        elif result["required_token_found"] is False:
            result["pass"] = False
            result["failure"] = "required_content_signal_missing"
        else:
            result["pass"] = True

        if source.get("compare_static_baseline"):
            baseline = engine.collect(
                EngineRequest(
                    url=source["url"],
                    mode="static_http",
                    timeout_ms=30_000,
                )
            )
            baseline_headers = dict(baseline.metadata.get("response_headers", {}) or {})
            baseline_text_length = int(
                baseline.metadata.get("response_text_length", 0) or 0
            )
            result["static_baseline"] = {
                "status": baseline.status,
                "final_url": baseline.final_url,
                "body_bytes": len(baseline.body),
                "raw_hash": build_evidence(
                    source_id=f"maistio-shadow:{source['key']}:static-baseline",
                    source_url=baseline.final_url,
                    body=baseline.body,
                    collection_method="static_http",
                    http_status=baseline.status,
                    rights_status="public_permitted",
                    response_meta=dict(baseline.metadata),
                ).raw_hash,
                "text_length": baseline_text_length,
                "content_type": content_type(baseline_headers),
            }
            result["dynamic_render_gain_text_chars"] = (
                result["text_length"] - baseline_text_length
            )
            result["dynamic_hash_differs"] = (
                result["raw_hash"] != result["static_baseline"]["raw_hash"]
            )
            result["dynamic_discovery_gain"] = (
                result["dynamic_render_gain_text_chars"] > 50
                or result["captured_xhr_count"] > 0
            )
            if not result["dynamic_discovery_gain"]:
                result["pass"] = False
                result["failure"] = "dynamic_route_added_no_render_or_xhr_evidence"

        results.append(result)

    output = {
        "pilot": "maistio-finland-web-acquisition-shadow-v1",
        "project_writes": 0,
        "canonical_promotions": 0,
        "results": results,
        "all_routes_executed": all(r["pass"] for r in results),
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))

    if not output["all_routes_executed"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
