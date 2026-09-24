# Architecture v1

## Position

Meterion Web Acquisition Layer sits between external web sources and project-specific raw/candidate ingestion.

```text
External source
  -> Source discovery / profile
  -> Route selection
     -> deterministic fast path
     -> Jev decision gate for material ambiguity
  -> CollectionEngine
     -> Scrapling static / dynamic / stealth provider
     -> future providers
  -> immutable-ish raw evidence + content hash
  -> deterministic validation
  -> exception bundle / Jev quality gate when needed
  -> promote | review | reject | repair_adapter | defer_refresh
  -> project adapter
  -> project canonical model
```

## Ownership boundaries

Shared layer owns:
- routing hierarchy
- collection engine interface
- source profiles
- response/snapshot evidence contract
- failure classification
- deterministic generic validation
- Jev gate payloads
- run metrics

Project owns:
- target entity semantics
- parser/extractor logic
- entity resolution rules
- field authority rules
- canonical schema
- canonical writes
- project-specific rights decisions
- freshness targets per field

## AI Company OS mapping

- Perception: source observations, normalization envelopes, source profile state.
- Decision: deterministic route + Jev only when ambiguity is material.
- Execution Plane: collection engine/provider adapter and bounded retries.
- Evidence: raw hash/snapshot, method, source identity, timestamps and validation outcomes.
- Learning: update source profiles from verified run history.

The acquisition layer does not become a second source of truth.
