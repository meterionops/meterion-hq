from __future__ import annotations

import json
from dataclasses import dataclass


@dataclass(frozen=True)
class StructuredExtraction:
    body: bytes
    extractor_id: str
    extractor_version: str
    content_type: str


def extract_wordpress_rendered_content(body: bytes) -> StructuredExtraction:
    """Extract WordPress REST page/post rendered HTML without domain semantics.

    Expected public REST shape:
      {"content": {"rendered": "<p>...</p>"}}

    Fail closed when the response is not valid JSON or does not contain a
    non-empty rendered content string. The caller can fall back to the source
    profile's cheaper verified route instead of inventing content.
    """
    try:
        payload = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError("invalid_wordpress_json") from exc

    content = payload.get("content")
    if not isinstance(content, dict):
        raise ValueError("missing_wordpress_content")

    rendered = content.get("rendered")
    if not isinstance(rendered, str) or not rendered.strip():
        raise ValueError("missing_wordpress_rendered_content")

    return StructuredExtraction(
        body=rendered.encode("utf-8"),
        extractor_id="wordpress_content_rendered",
        extractor_version="v1",
        content_type="text/html; charset=utf-8",
    )
