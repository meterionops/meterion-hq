from __future__ import annotations

import json
from html.parser import HTMLParser

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
        "key": "dynamic_thai_burpha_lunch",
        "url": "https://www.thaiburpha.fi/lounas",
        "target": "lunch",
        "expected_mode": "dynamic_browser",
        "observation": {
            "requires_javascript": True,
            "rights_status": "public_permitted",
        },
        "required_token": "Maanantaina",
        "compare_static_baseline": True,
        "capture_xhr": ".*",
        "wait_ms": 2500,
    },
]


class VisibleTextParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: list[str] = []
        self.skip_depth = 0

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag.lower() in {"script", "style", "noscript", "svg"}:
            self.skip_depth += 1

    def handle_endtag(self, tag: str) -> None:
        if tag.lower() in {"script", "style", "noscript", "svg"} and self.skip_depth:
            self.skip_depth -= 1

    def handle_data(self, data: str) -> None:
        if self.skip_depth == 0:
            value = data.strip()
            if value:
                self.parts.append(value)


def visible_text(body: bytes, content_type_value: str | None) -> str:
    decoded = body.decode("utf-8", errors="ignore")
    if content_type_value and "html" not in content_type_value.lower():
        return decoded
    parser = VisibleTextParser()
    parser.feed(decoded)
    return " ".join(parser.parts)


def content_type(headers: dict) -> str | None:
    for key, value in headers.items():
        if str(key).lower() == "content-type":
            return str(value)
    return None


def visible_contains(body: bytes, token: str | None, content_type_value: str | None) -> bool | None:
    if not token:
        return None
    return token.lower() in visible_text(body, content_type_value).lower()


def result_for_response(source: dict, decision, response, evidence) -> dict:
    headers = dict(response.metadata.get("response_headers", {}) or {})
    type_value = content_type(headers)
    text_length = int(response.metadata.get("response_text_length", 0) or 0)
    token = source.get("required_token")
    extraction = response.content_for_extraction
    return {
        "key": source["key"],
        "requested_url": source["url"],
        "final_url": response.final_url,
        "route": decision.mode,
        "route_reason": decision.reason,
        "status": response.status,
        "content_type": type_value,
        "body_bytes": evidence.body_bytes,
        "raw_hash": evidence.raw_hash,
        "extraction_bytes": evidence.extraction_bytes,
        "extraction_hash": evidence.extraction_hash,
        "extraction_kind": response.metadata.get("extraction_kind"),
        "text_length": text_length,
        "redirect_count": int(response.metadata.get("redirect_count", 0) or 0),
        "captured_xhr_count": int(response.metadata.get("captured_xhr_count", 0) or 0),
        "rights_status": evidence.rights_status,
        "required_token": token,
        "required_token_found": visible_contains(extraction, token, type_value),
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
            extraction_body=response.content_for_extraction,
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
            baseline_type = content_type(baseline_headers)
            baseline_text_length = int(
                baseline.metadata.get("response_text_length", 0) or 0
            )
            baseline_extraction = baseline.content_for_extraction
            baseline_token_found = visible_contains(
                baseline_extraction, source.get("required_token"), baseline_type
            )
            baseline_evidence = build_evidence(
                source_id=f"maistio-shadow:{source['key']}:static-baseline",
                source_url=baseline.final_url,
                body=baseline.body,
                extraction_body=baseline_extraction,
                collection_method="static_http",
                http_status=baseline.status,
                rights_status="public_permitted",
                response_meta=dict(baseline.metadata),
            )
            result["static_baseline"] = {
                "status": baseline.status,
                "final_url": baseline.final_url,
                "body_bytes": baseline_evidence.body_bytes,
                "raw_hash": baseline_evidence.raw_hash,
                "extraction_bytes": baseline_evidence.extraction_bytes,
                "extraction_hash": baseline_evidence.extraction_hash,
                "text_length": baseline_text_length,
                "content_type": baseline_type,
                "required_token_found": baseline_token_found,
            }
            result["dynamic_render_gain_text_chars"] = (
                result["text_length"] - baseline_text_length
            )
            result["dynamic_target_gain"] = (
                result["required_token_found"] is True
                and baseline_token_found is False
            )
            if not result["dynamic_target_gain"]:
                result["pass"] = False
                result["failure"] = "dynamic_route_did_not_add_visible_target_evidence"

        results.append(result)

    output = {
        "pilot": "maistio-finland-web-acquisition-shadow-v1",
        "project_writes": 0,
        "canonical_promotions": 0,
        "results": results,
        "all_routes_verified": all(r["pass"] for r in results),
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))

    if not output["all_routes_verified"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
