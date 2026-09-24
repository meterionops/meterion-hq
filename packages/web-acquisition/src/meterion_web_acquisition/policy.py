from __future__ import annotations

from .models import CollectionJob, RoutingDecision, SourceObservation


def route_collection(job: CollectionJob, source: SourceObservation) -> RoutingDecision:
    """Deterministic fast path for collection routing.

    Return `needs_jev=True` only when evidence is insufficient or an expensive
    escalation is being considered. Jev should receive the same observed state,
    not hidden assumptions.
    """
    if source.rights_status == "prohibited":
        return RoutingDecision(
            mode="research_pause",
            reason="source rights/access prohibit automated collection",
            needs_jev=False,
        )

    if source.rights_status in {"manual_only", "unknown"}:
        return RoutingDecision(
            mode="research_pause",
            reason="rights/access status is not sufficient for autonomous collection",
            needs_jev=True,
        )

    if source.has_official_api_or_feed or source.has_public_structured_endpoint:
        return RoutingDecision(
            mode="api_feed",
            reason="structured public source is available",
        )

    if source.static_html_contains_target:
        return RoutingDecision(
            mode="static_http",
            reason="target evidence is available in static HTML",
        )

    if source.has_public_xhr_endpoint:
        return RoutingDecision(
            mode="api_feed",
            reason="public page exposes a structured XHR/fetch endpoint",
        )

    if source.requires_javascript and not source.ordinary_browser_blocked:
        return RoutingDecision(
            mode="dynamic_browser",
            reason="target evidence requires JavaScript rendering",
        )

    if source.ordinary_browser_blocked:
        if source.allow_stealth:
            return RoutingDecision(
                mode="stealth_browser",
                reason="ordinary browser collection is blocked and a permitted stealth path is explicitly allowed",
                needs_jev=True,
            )
        return RoutingDecision(
            mode="research_pause",
            reason="ordinary browser collection is blocked; do not escalate without explicit rights and routing review",
            needs_jev=True,
        )

    return RoutingDecision(
        mode="research_pause",
        reason=f"insufficient source evidence to route job {job.job_id}",
        needs_jev=True,
    )
