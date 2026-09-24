from __future__ import annotations

from .models import (
    CollectionJob,
    RightsStatus,
    RoutingDecision,
    SourceObservation,
    SourceProfile,
)


def source_observation_from_profile(
    profile: SourceProfile,
    *,
    rights_status: RightsStatus,
) -> SourceObservation:
    """Convert only verified profile state into a deterministic route observation.

    A CMS/platform label alone must never create a route. An api_feed profile
    requires a verified endpoint stored on this specific source profile.
    """
    if profile.preferred_mode == "api_feed":
        if not profile.public_endpoints:
            return SourceObservation(
                rights_status=rights_status,
                notes=("api_feed profile has no verified endpoint",),
            )
        return SourceObservation(
            has_public_structured_endpoint=True,
            preferred_fetch_url=profile.public_endpoints[0],
            rights_status=rights_status,
            notes=("verified endpoint profile",),
        )

    if profile.preferred_mode == "static_http":
        return SourceObservation(
            static_html_contains_target=True,
            rights_status=rights_status,
            notes=("verified static profile",),
        )

    if profile.preferred_mode == "dynamic_browser":
        return SourceObservation(
            requires_javascript=True,
            rights_status=rights_status,
            notes=("verified dynamic profile",),
        )

    return SourceObservation(
        rights_status=rights_status,
        notes=("profile has no verified preferred route",),
    )


def route_collection(job: CollectionJob, source: SourceObservation) -> RoutingDecision:
    """Deterministic fast path for collection routing.

    Return needs_jev=True only when evidence is insufficient or an expensive
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

    if (
        source.has_official_api_or_feed
        or source.has_public_structured_endpoint
        or source.has_public_xhr_endpoint
    ):
        return RoutingDecision(
            mode="api_feed",
            reason="structured public source or page endpoint is available",
            fetch_url=source.preferred_fetch_url or job.source_url,
        )

    if source.static_html_contains_target:
        return RoutingDecision(
            mode="static_http",
            reason="target evidence is available in static HTML",
            fetch_url=job.source_url,
        )

    if source.requires_javascript and not source.ordinary_browser_blocked:
        return RoutingDecision(
            mode="dynamic_browser",
            reason="target evidence requires JavaScript rendering",
            fetch_url=job.source_url,
        )

    if source.ordinary_browser_blocked:
        if source.allow_stealth:
            return RoutingDecision(
                mode="stealth_browser",
                reason="ordinary browser collection is blocked and a permitted stealth path is explicitly allowed",
                needs_jev=True,
                fetch_url=job.source_url,
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
