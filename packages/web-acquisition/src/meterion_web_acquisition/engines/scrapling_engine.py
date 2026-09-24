from __future__ import annotations

from typing import Any

from ..engine import EngineRequest, EngineResponse


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
                "Scrapling is not installed. Install meterion-web-acquisition[scrapling]."
            ) from exc

        if request.mode in {"api_feed", "static_http"}:
            if request.adaptive:
                Fetcher.configure(adaptive=True)
            page = Fetcher.get(request.url, timeout=request.timeout_ms)
        elif request.mode == "dynamic_browser":
            if request.adaptive:
                DynamicFetcher.configure(adaptive=True)
            page = DynamicFetcher.fetch(
                request.url,
                timeout=request.timeout_ms,
                network_idle=request.network_idle,
                disable_resources=request.disable_resources,
            )
        elif request.mode == "stealth_browser":
            if request.adaptive:
                StealthyFetcher.configure(adaptive=True)
            page = StealthyFetcher.fetch(
                request.url,
                timeout=request.timeout_ms,
                network_idle=request.network_idle,
                disable_resources=request.disable_resources,
            )
        else:
            raise ValueError(f"Unsupported Scrapling collection mode: {request.mode}")

        body = bytes(page.body)
        final_url = str(getattr(page, "url", request.url) or request.url)
        meta: dict[str, Any] = dict(getattr(page, "meta", {}) or {})
        return EngineResponse(
            body=body,
            status=getattr(page, "status", None),
            final_url=final_url,
            metadata=meta,
        )
