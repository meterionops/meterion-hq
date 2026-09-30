# Meterion Web Acquisition Layer

Shared acquisition boundary for Meterion data products.

The layer owns **how public source evidence is acquired and qualified**. It does not own product-specific canonical schemas.

```text
source
  -> route
  -> collection engine
  -> raw evidence
  -> deterministic validation
  -> Jev gate when needed
  -> candidate decision
  -> project adapter
  -> project canonical model
```

## Locked principles

1. Evidence before canonical truth.
2. Prefer structured/public endpoints, then static HTTP, then browser rendering.
3. Scrapling is a provider, not the architecture.
4. Jev decides ambiguous routing/quality questions; it never invents source facts.
5. Project adapters own domain semantics and canonical writes.
6. Adaptive relocation creates a candidate observation, never automatic truth.
7. Rights/access failures do not escalate into bypass tactics.
8. Source profiles learn stable endpoints, selectors, failure modes and refresh behavior.

## Package boundary

The package is intentionally domain-neutral. Maistio, Calendar Platform, Cala Europe, Nordic Bottle Index, Sprinkler Hub and future products may consume the same contracts while keeping their own parsers and canonical models.

The first provider is Scrapling 0.4.15. Additional providers can implement the same `CollectionEngine` protocol.

## Example

```python
from meterion_web_acquisition import (
    CollectionJob,
    SourceObservation,
    route_collection,
)

job = CollectionJob(
    job_id="maistio-menu-001",
    project_key="maistio",
    source_url="https://restaurant.example/menu",
    target="menu",
    fields=("dish_name", "price"),
    recurring=True,
)

observation = SourceObservation(
    has_public_structured_endpoint=True,
    static_html_contains_target=False,
    requires_javascript=True,
    rights_status="public_permitted",
)

decision = route_collection(job, observation)
assert decision.mode == "api_feed"
```

## Jev integration

The package exposes stable gate payloads and an interface for a Jev decision provider. The ChatGPT `meterion-web-data-collector` Skill can satisfy that interface through the connected Jev tools. Runtime services may provide another Jev adapter later without changing project code.

## Placement

This package lives under `meterion-hq/packages/web-acquisition` until a dedicated `meterionops/meterion-web-acquisition` repository is available. The package has no dependency on Meterion HQ internals and is extraction-ready.
