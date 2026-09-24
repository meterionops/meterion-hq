from __future__ import annotations

import hashlib
from typing import Any

from ..engine import EngineRequest, EngineResponse


def _header_value(headers: dict, name: str) -> str | None:
    target = name.lower()
    for key, value in headers.items():
        if str(key).lower() == target:
            return str(value)
    return None


class ScraplingEngine:
    """Scrapling provider adapter.

    Import is lazy so the shared core can be used in services that do not have
    browser dependencies installed. Version 0.4.15 is the tested package extra.
    """

    name = "scrapling"

    def collect(self, request: EngineRequest) -> EngineResponse:
        try:
            from scrapling.fetchers import DynamicFetcher, Fetcher, StealthyFetcher
        except Exception as exc:  # pragma: no cover - environment dependent
            raise RuntimeError(
                "Scrapling fetchers are not installed. Install meterion-web-acquisition[scrapling]."
            ) from exc

        if request.mode in {"api_feed", "static_http"}:
            if request.adaptive:
                Fetcher.configure(adaptive=True)
            page = Fetcher.get(
                request.url,
                timeout=max(request.timeout_ms / 1000.0, 0.001),
            )
        elif request.mode == "dynamic_browser":
            if request.adaptive:
                DynamicFetcher.configure(adaptive=True)
            page = DynamicFetcher.fetch(
                request.url,
                timeout=request.timeout_ms,
                wait=request.wait_ms,
                network_idle=request.network_idle,
                disable_resources=request.disable_resources,
                capture_xhr=request.capture_xhr_pattern,
            )
        elif request.mode == "stealth_browser":
            if request.adaptive:
                StealthyFetcher.configure(adaptive=True)
            page = StealthyFetcher.fetch(
                request.url,
                timeout=request.timeout_ms,
                wait=request.wait_ms,
                network_idle=request.network_idle,
                disable_resources=request.disable_resources,
                capture_xhr=request.capture_xhr_pattern,
            )
        else:
            raise ValueError(f"Unsupported Scrapling collection mode: {request.mode}")

        body = bytes(page.body)
        final_url = str(getattr(page, "url", request.url) or request.url)
        headers = dict(getattr(page, "headers", {}) or {})
        history = list(getattr(page, "history", []) or [])
        captured_xhr = list(getattr(page, "captured_xhr", []) or [])

        try:
            page_text = str(page.get_all_text(separator=" ", strip=True) or "")
        except Exception:
            page_text = ""

        xhr_summaries: list[dict[str, Any]] = []
        for xhr in captured_xhr[:100]:
            try:
                xhr_body = bytes(xhr.body)
            except Exception:
                xhr_body = b""
            xhr_headers = dict(getattr(xhr, "headers", {}) or {})
            xhr_summaries.append(
                {
                    "url": str(getattr(xhr, "url", "") or ""),
                    "status": getattr(xhr, "status", None),
                    "content_type": _header_value(xhr_headers, "content-type"),
                    "body_bytes": len(xhr_body),
                    "raw_hash": (
                        "sha256:" + hashlib.sha256(xhr_body).hexdigest()
                        if xhr_body
                        else None
                    ),
                }
            )

        meta: dict[str, Any] = dict(getattr(page, "meta", {}) or {})
        meta.update(
            {
                "response_headers": headers,
                "redirect_count": len(history),
                "captured_xhr_count": len(captured_xhr),
                "captured_xhr_summaries": xhr_summaries,
                "response_text_length": len(page_text),
            }
        )
        return EngineResponse(
            body=body,
            status=getattr(page, "status", None),
            final_url=final_url,
            metadata=meta,
        )
