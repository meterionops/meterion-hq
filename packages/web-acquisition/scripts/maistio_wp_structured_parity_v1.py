from __future__ import annotations

import html
import json
import re
from html.parser import HTMLParser

from meterion_web_acquisition import EngineRequest, build_evidence
from meterion_web_acquisition.engines.scrapling_engine import ScraplingEngine


SOURCES = [
    {
        "key": "annes_vege_menu",
        "restaurant": "Anne's Vege",
        "city": "Espoo",
        "source_types": ["menu"],
        "page_url": "https://www.annesvege.fi/#ruokalista",
        "endpoint_url": "https://www.annesvege.fi/wp-json/wp/v2/pages/8",
    },
    {
        "key": "jarvenpera_lunch",
        "restaurant": "Jarvenperan Ravintola",
        "city": "Espoo",
        "source_types": ["lunch"],
        "page_url": "https://jarvenperanravintola.fi/lounas/",
        "endpoint_url": "https://jarvenperanravintola.fi/wp-json/wp/v2/pages/16",
    },
    {
        "key": "lime_leaf_menu",
        "restaurant": "Lime Leaf",
        "city": "Espoo",
        "source_types": ["menu"],
        "page_url": "https://limerestaurants.fi/lime-leaf-menu/",
        "endpoint_url": "https://limerestaurants.fi/wp-json/wp/v2/pages/80",
    },
    {
        "key": "mandarin_palace_menu",
        "restaurant": "Mandarin Palace",
        "city": "Espoo",
        "source_types": ["menu"],
        "page_url": "https://mandarinpalace.fi/#menu",
        "endpoint_url": "https://mandarinpalace.fi/wp-json/wp/v2/pages/3210",
    },
    {
        "key": "orient_express_menu",
        "restaurant": "Orient Express",
        "city": "Espoo",
        "source_types": ["lunch", "menu"],
        "page_url": "https://orientexpress.fi/",
        "endpoint_url": "https://orientexpress.fi/wp-json/wp/v2/pages/133",
    },
    {
        "key": "birdie_numnum_menu",
        "restaurant": "Birdie Numnum",
        "city": "Helsinki",
        "source_types": ["menu"],
        "page_url": "https://birdienumnum.fi/#menu",
        "endpoint_url": "https://birdienumnum.fi/wp-json/wp/v2/pages/7",
    },
    {
        "key": "brasserie_lionne_breakfast",
        "restaurant": "Brasserie Lionne",
        "city": "Helsinki",
        "source_types": ["breakfast", "menu"],
        "page_url": "https://brasserielionne.fi/menus/breakfast/",
        "endpoint_url": "https://brasserielionne.fi/wp-json/wp/v2/pages/3626",
    },
    {
        "key": "don_corleone_drinks_wine",
        "restaurant": "Don Corleone",
        "city": "Helsinki",
        "source_types": ["drinks", "wine"],
        "page_url": "https://doncorleone.fi/viini-juomat/",
        "endpoint_url": "https://doncorleone.fi/wp-json/wp/v2/pages/132",
    },
    {
        "key": "harju8_brunch",
        "restaurant": "Ravintola Harju 8",
        "city": "Helsinki",
        "source_types": ["brunch"],
        "page_url": "https://harju8.fi/brunch/",
        "endpoint_url": "https://harju8.fi/wp-json/wp/v2/pages/135",
    },
    {
        "key": "lehtovaara_alacarte",
        "restaurant": "Lehtovaara Restaurant",
        "city": "Helsinki",
        "source_types": ["menu"],
        "page_url": "https://www.lehtovaara.fi/a-la-carte/",
        "endpoint_url": "https://www.lehtovaara.fi/wp-json/wp/v2/pages/41",
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


def normalize_text(value: str) -> str:
    value = html.unescape(value)
    value = value.replace("\u00a0", " ")
    return re.sub(r"\s+", " ", value).strip()


def visible_text(raw_html: str) -> str:
    parser = VisibleTextParser()
    parser.feed(raw_html)
    return normalize_text(" ".join(parser.parts))


def significant_tokens(value: str) -> set[str]:
    stop = {
        "menu", "home", "restaurant", "ravintola", "helsinki", "espoo",
        "food", "page", "read", "more", "the", "and", "with", "from",
        "this", "that", "your", "our", "seka", "joka", "ovat", "tama",
        "ruokalista",
    }
    tokens = {
        token.lower()
        for token in re.findall(r"[A-Za-zÀ-ÖØ-öø-ÿ0-9][A-Za-zÀ-ÖØ-öø-ÿ0-9'-]{3,}", value)
    }
    return {token for token in tokens if token not in stop}


def overlap_ratio(endpoint_text: str, page_text: str) -> float:
    endpoint_tokens = significant_tokens(endpoint_text)
    if not endpoint_tokens:
        return 0.0
    page_tokens = significant_tokens(page_text)
    return len(endpoint_tokens & page_tokens) / len(endpoint_tokens)


def price_signal_count(value: str) -> int:
    patterns = [
        r"\b\d{1,3}[,.]\d{2}\s*(?:€|eur)\b",
        r"(?:€|eur)\s*\d{1,3}[,.]\d{2}\b",
        r"\b\d{1,3}[,.]\d{2}\b",
    ]
    found: set[str] = set()
    lower = value.lower()
    for pattern in patterns:
        found.update(re.findall(pattern, lower, flags=re.IGNORECASE))
    return len(found)


def target_signal_count(value: str, source_types: list[str]) -> int:
    lower = value.lower()
    terms = {
        "menu": ["menu", "ruokalista", "a la carte", "à la carte", "starter", "alkuruo", "paaruo", "pääruo"],
        "lunch": ["lounas", "lunch"],
        "breakfast": ["aamiainen", "breakfast"],
        "brunch": ["brunssi", "brunch"],
        "drinks": ["juoma", "drink", "cocktail", "olut", "beer"],
        "wine": ["viini", "wine", "weine", "vin"],
    }
    hits = 0
    for source_type in source_types:
        if any(term in lower for term in terms.get(source_type, [])):
            hits += 1
    return hits


def endpoint_document(body: bytes) -> tuple[dict, str, str]:
    payload = json.loads(body.decode("utf-8"))
    title = ""
    content_html = ""
    if isinstance(payload, dict):
        title_obj = payload.get("title") or {}
        content_obj = payload.get("content") or {}
        if isinstance(title_obj, dict):
            title = str(title_obj.get("rendered") or "")
        if isinstance(content_obj, dict):
            content_html = str(content_obj.get("rendered") or "")
    text = normalize_text(" ".join([visible_text(title), visible_text(content_html)]))
    return payload, content_html, text


def main() -> None:
    engine = ScraplingEngine()
    results: list[dict] = []

    for source in SOURCES:
        page = engine.collect(
            EngineRequest(url=source["page_url"], mode="static_http", timeout_ms=30000)
        )
        endpoint = engine.collect(
            EngineRequest(url=source["endpoint_url"], mode="api_feed", timeout_ms=30000)
        )

        page_evidence = build_evidence(
            source_id=f"maistio-wp-parity:{source['key']}:page",
            source_url=page.final_url,
            body=page.body,
            collection_method="static_http",
            http_status=page.status,
            rights_status="public_permitted",
            response_meta=dict(page.metadata),
        )
        endpoint_evidence = build_evidence(
            source_id=f"maistio-wp-parity:{source['key']}:endpoint",
            source_url=endpoint.final_url,
            body=endpoint.body,
            collection_method="api_feed",
            http_status=endpoint.status,
            rights_status="public_permitted",
            response_meta=dict(endpoint.metadata),
        )

        page_text = visible_text(page.body.decode("utf-8", errors="ignore"))
        error = None
        endpoint_text = ""
        content_html = ""
        try:
            _, content_html, endpoint_text = endpoint_document(endpoint.body)
        except Exception as exc:
            error = f"endpoint_json:{type(exc).__name__}"

        overlap = overlap_ratio(endpoint_text, page_text) if endpoint_text else 0.0
        prices = price_signal_count(endpoint_text)
        target_hits = target_signal_count(endpoint_text, source["source_types"])
        byte_reduction = 0.0
        if page_evidence.body_bytes:
            byte_reduction = 1.0 - (
                endpoint_evidence.body_bytes / page_evidence.body_bytes
            )

        status_ok = (
            page.status is not None
            and 200 <= page.status < 300
            and endpoint.status is not None
            and 200 <= endpoint.status < 300
        )
        content_ok = len(endpoint_text) >= 150
        semantic_ok = target_hits > 0 or prices >= 2
        overlap_ok = overlap >= 0.55

        if status_ok and content_ok and semantic_ok and overlap_ok and not error:
            verdict = "parity_pass"
        elif status_ok and len(endpoint_text) >= 80 and not error:
            verdict = "review_partial"
        else:
            verdict = "reject_endpoint"

        results.append(
            {
                **{
                    k: source[k]
                    for k in [
                        "key",
                        "restaurant",
                        "city",
                        "source_types",
                        "page_url",
                        "endpoint_url",
                    ]
                },
                "page_status": page.status,
                "endpoint_status": endpoint.status,
                "page_bytes": page_evidence.body_bytes,
                "endpoint_bytes": endpoint_evidence.body_bytes,
                "byte_reduction_ratio": round(byte_reduction, 4),
                "page_text_chars": len(page_text),
                "endpoint_text_chars": len(endpoint_text),
                "endpoint_content_html_chars": len(content_html),
                "endpoint_to_page_token_overlap": round(overlap, 4),
                "endpoint_price_signals": prices,
                "endpoint_target_type_signals": target_hits,
                "raw_page_hash": page_evidence.raw_hash,
                "raw_endpoint_hash": endpoint_evidence.raw_hash,
                "error": error,
                "verdict": verdict,
            }
        )

    counts = {
        key: sum(1 for result in results if result["verdict"] == key)
        for key in ["parity_pass", "review_partial", "reject_endpoint"]
    }
    average_reduction = sum(
        result["byte_reduction_ratio"] for result in results
    ) / len(results)
    summary = {
        "pilot": "maistio-wordpress-structured-parity-v1",
        "project_writes": 0,
        "canonical_promotions": 0,
        "cohort_size": len(results),
        "counts": counts,
        "average_byte_reduction_ratio": round(average_reduction, 4),
        "learn_wordpress_as_preferred_route": (
            counts["parity_pass"] >= 7 and counts["reject_endpoint"] == 0
        ),
        "results": results,
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
