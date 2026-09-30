from __future__ import annotations

import hashlib
from typing import Any

from ..engine import CapturedResponse, EngineRequest, EngineResponse
from ..evidence import utc_now_iso

MAX_XHR_RESPONSES = 100
MAX_XHR_BODY_BYTES = 2 * 1024 * 1024
MAX_XHR_TOTAL_BYTES = 10 * 1024 * 1024


def capture_responses(captured_xhr, retain: bool):
    """Bound retained copies. Provider/browser buffering occurs before this step."""
    results = []
    retained_bytes = 0
    for xhr in captured_xhr[:MAX_XHR_RESPONSES]:
        body = None
        size = None
        digest = None
        reason = None
        try:
            raw = xhr.body
            if not isinstance(raw, (bytes, bytearray)):
                raise TypeError('body is not bytes')
            size = len(raw)
            digest = 'sha256:' + hashlib.sha256(raw).hexdigest()
            if not retain:
                reason = 'retention_not_requested'
            elif size > MAX_XHR_BODY_BYTES:
                reason = 'body_size_limit'
            elif retained_bytes + size > MAX_XHR_TOTAL_BYTES:
                reason = 'total_size_limit'
            else:
                body = bytes(raw)
                retained_bytes += size
        except Exception:
            reason = 'body_unavailable'
        results.append(CapturedResponse(
            url=str(getattr(xhr, 'url', '') or ''),
            status=getattr(xhr, 'status', None),
            content_type=_header_value(dict(getattr(xhr, 'headers', {}) or {}), 'content-type'),
            body=body, body_bytes=size, raw_hash=digest, omission_reason=reason,
        ))
    return tuple(results)


def _header_value(headers: dict, name: str) -> str | None:
    target = name.lower()
    for key, value in headers.items():
        if str(key).lower() == target:
            return str(value)
    return None


class ScraplingEngine:
    """Scrapling provider adapter.

    The raw network body is retained as `body`. For browser routes,
    `extraction_body` is a serialized rendered DOM snapshot so project
    extractors can consume content that only exists after JavaScript execution.
    """

    name = "scrapling"

    def collect(self, request: EngineRequest) -> EngineResponse:
        if request.retain_xhr_bodies and not request.capture_xhr_pattern:
            raise ValueError('XHR body retention requires an explicit capture pattern')
        try:
            from scrapling.fetchers import DynamicFetcher, Fetcher, StealthyFetcher
        except Exception as exc:  # pragma: no cover - environment dependent
            raise RuntimeError(
                "Scrapling fetchers are not installed. Install meterion-web-acquisition[scrapling]."
            ) from exc

        browser_mode = request.mode in {"dynamic_browser", "stealth_browser"}

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
        extraction_body = body
        final_url = str(getattr(page, "url", request.url) or request.url)
        headers = dict(getattr(page, "headers", {}) or {})
        history = list(getattr(page, "history", []) or [])
        captured_xhr = list(getattr(page, "captured_xhr", []) or [])

        try:
            page_text = str(page.get_all_text(separator=" ", strip=True) or "")
        except Exception:
            page_text = ""

        if browser_mode:
            try:
                rendered_html = str(page.get() or "")
            except Exception:
                rendered_html = ""
            if rendered_html:
                extraction_body = rendered_html.encode("utf-8", errors="replace")

        retained_xhr = capture_responses(captured_xhr, request.retain_xhr_bodies)
        xhr_summaries = [dict(
            url=x.url, status=x.status, content_type=x.content_type,
            body_bytes=x.body_bytes, raw_hash=x.raw_hash,
            body_retained=x.body is not None, omission_reason=x.omission_reason,
        ) for x in retained_xhr]

        meta: dict[str, Any] = dict(getattr(page, "meta", {}) or {})
        meta.update(
            {
                "response_headers": headers,
                "requested_fetch_url": request.url,
                "collection_method": request.mode,
                "fetched_at": utc_now_iso(),
                "redirect_count": len(history),
                "captured_xhr_count": len(captured_xhr),
                "captured_xhr_summaries": xhr_summaries,
                "captured_xhr_omitted_count": max(0, len(captured_xhr) - MAX_XHR_RESPONSES),
                "response_text_length": len(page_text),
                "extraction_kind": "rendered_dom" if browser_mode else "raw_response",
            }
        )
        return EngineResponse(
            body=body,
            extraction_body=extraction_body,
            status=getattr(page, "status", None),
            final_url=final_url,
            metadata=meta,
            captured_responses=retained_xhr,
        )
