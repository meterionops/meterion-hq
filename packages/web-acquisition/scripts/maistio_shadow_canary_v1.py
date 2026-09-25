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
        "source_url": "https://www.ravintolamantra.fi/menu",
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
        "source_url": "https://www.rodeosteakhouse.fi/menu/",
        "target": "menu",
        "expected_mode": "api_feed",
        "observation": {
            "has_public_structured_endpoint": True,
            "preferred_fetch_url": "https://www.rodeosteakhouse.fi/wp-json/wp/v2/pages/319",
            "rights_status": "public_permitted",
        },
        "required_token": "Rodeo",
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


def main() -> None:
    engine = ScraplingEngine()
    results: list[dict] = []

    for source in SOURCES:
        job = CollectionJob(
            job_id=f"maistio-shadow-{source['key']}",
            project_key="maistio",
            source_url=source["source_url"],
            target=source["target"],
            recurring=False,
        )
        observation = SourceObservation(**source["observation"])
        decision = route_collection(job, observation)
        if decision.mode != source["expected_mode"]:
            raise AssertionError(
                f"{source['key']}: expected {source['expected_mode']}, got {decision.mode}"
            )

        fetch_url = decision.fetch_url or job.source_url
        response = engine.collect(
            EngineRequest(
                url=fetch_url,
                mode=decision.mode,
                timeout_ms=30_000,
            )
        )
        response_meta = dict(response.metadata)
        response_meta.update(
            {
                "source_identity_url": job.source_url,
                "requested_fetch_url": fetch_url,
            }
        )
        evidence = build_evidence(
            source_id=f"maistio-shadow:{source['key']}",
            source_url=response.final_url,
            body=response.body,
            extraction_body=response.content_for_extraction,
            collection_method=decision.mode,
            http_status=response.status,
            rights_status="public_permitted",
            response_meta=response_meta,
        )

        headers = dict(response.metadata.get("response_headers", {}) or {})
        type_value = content_type(headers)
        extraction_text = visible_text(response.content_for_extraction, type_value)
        token_found = source["required_token"].lower() in extraction_text.lower()

        result = {
            "key": source["key"],
            "source_identity_url": job.source_url,
            "requested_fetch_url": fetch_url,
            "final_url": response.final_url,
            "route": decision.mode,
            "status": response.status,
            "content_type": type_value,
            "body_bytes": evidence.body_bytes,
            "raw_hash": evidence.raw_hash,
            "extraction_bytes": evidence.extraction_bytes,
            "extraction_hash": evidence.extraction_hash,
            "required_token": source["required_token"],
            "required_token_found": token_found,
            "pass": (
                response.status is not None
                and 200 <= response.status < 300
                and token_found
            ),
        }
        results.append(result)

    verified = all(row["pass"] for row in results)
    output = {
        "pilot": "maistio-finland-web-acquisition-shadow-v1",
        "project_writes": 0,
        "canonical_promotions": 0,
        "verified_routes": ["static_http", "api_feed"] if verified else [],
        "dynamic_browser_status": "EVIDENCE_REQUIRED",
        "dynamic_browser_note": (
            "Current Maistio probes did not find a source where browser rendering "
            "added relevant target-bearing evidence over cheaper routes."
        ),
        "results": results,
        "verified_core_routes_pass": verified,
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))

    if not verified:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
