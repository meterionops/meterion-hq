from __future__ import annotations

import json
import re
from html.parser import HTMLParser

from meterion_web_acquisition import EngineRequest
from meterion_web_acquisition.engines.scrapling_engine import ScraplingEngine


SOURCES = [
    ("toscona_menu", "Ravintola Toscana", "https://www.ravintolatoscana.fi/menu/"),
    ("saaribaari_menu", "Saaribaari", "https://saaribaari.fi/menu"),
    ("sopranos_lunch", "Pizzeria Sopranos", "https://www.pizzeria-sopranos.fi/lunch-lounas"),
    ("bistro_venla_drinks", "Bistro Venla", "https://bistro-venla.com/juomalista"),
    ("jonel_thai_menu", "Jonel Thai", "https://www.jonelthai.com/menu-2"),
    ("mamoste_lunch", "Mamoste", "https://www.mamoste.fi/lounas/"),
    ("metso_lunch", "Metso Kahvila", "https://www.cafemetso.fi/cafe-metson-lounas"),
    ("pyynikintori_menu", "Pyynikintorin Liha ja Kahvi", "https://www.pyynikintorinlihajakahvi.com/menu"),
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


def visible_text(body: bytes) -> str:
    parser = VisibleTextParser()
    parser.feed(body.decode("utf-8", errors="ignore"))
    return " ".join(parser.parts)


def words(text: str) -> set[str]:
    return {
        w.lower()
        for w in re.findall(r"[A-Za-zÀ-ÖØ-öø-ÿ0-9€]+", text)
        if len(w) >= 4
    }


def main() -> None:
    engine = ScraplingEngine()
    rows: list[dict] = []

    for key, restaurant, url in SOURCES:
        static = engine.collect(
            EngineRequest(url=url, mode="static_http", timeout_ms=30_000)
        )
        dynamic = engine.collect(
            EngineRequest(
                url=url,
                mode="dynamic_browser",
                timeout_ms=35_000,
                wait_ms=2000,
                network_idle=False,
                capture_xhr_pattern=".*",
            )
        )

        static_text = visible_text(static.content_for_extraction)
        dynamic_text = visible_text(dynamic.content_for_extraction)
        static_words = words(static_text)
        dynamic_words = words(dynamic_text)
        added = sorted(dynamic_words - static_words)

        static_len = len(static_text)
        dynamic_len = len(dynamic_text)
        gain = dynamic_len - static_len
        ratio = round(dynamic_len / max(static_len, 1), 3)

        rows.append(
            {
                "key": key,
                "restaurant": restaurant,
                "url": url,
                "static_status": static.status,
                "dynamic_status": dynamic.status,
                "static_text_chars": static_len,
                "dynamic_text_chars": dynamic_len,
                "text_gain_chars": gain,
                "text_gain_ratio": ratio,
                "static_body_bytes": len(static.body),
                "dynamic_raw_body_bytes": len(dynamic.body),
                "dynamic_rendered_bytes": len(dynamic.content_for_extraction),
                "captured_xhr_count": int(dynamic.metadata.get("captured_xhr_count", 0) or 0),
                "captured_xhr_summaries": list(dynamic.metadata.get("captured_xhr_summaries", []) or [])[:10],
                "added_word_sample": added[:40],
                "browser_value_candidate": (
                    static.status == 200
                    and dynamic.status == 200
                    and gain >= 250
                    and ratio >= 1.35
                    and len(added) >= 12
                ),
            }
        )

    ranked = sorted(
        rows,
        key=lambda r: (r["browser_value_candidate"], r["text_gain_chars"], r["text_gain_ratio"]),
        reverse=True,
    )
    print(
        json.dumps(
            {
                "probe": "maistio-dynamic-route-probe-v1",
                "project_writes": 0,
                "candidate_count": sum(1 for r in ranked if r["browser_value_candidate"]),
                "results": ranked,
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
