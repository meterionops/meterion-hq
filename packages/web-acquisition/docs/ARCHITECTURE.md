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
  -> immutable-ish raw response evidence
  -> extraction evidence when transport/rendering differs from raw response
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
- raw response + extraction evidence contracts
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

## Raw response vs extraction evidence

The transport response and the content supplied to a project extractor are not always the same object.

For static HTTP and structured endpoints:
- raw response = extraction content.

For browser-rendered routes:
- raw network response is retained unchanged for audit/replay;
- rendered DOM may be stored separately as extraction evidence;
- project parsers consume the rendered extraction content only when the route requires it.

Both raw and extraction hashes / byte sizes remain observable.

A browser route does not pass merely because the rendered hash differs from the raw response. It must add target-bearing evidence that was unavailable through a cheaper route.

## Source-profile learning rule

Discovery of an endpoint is not proof that the endpoint should become a preferred route.

Learn a structured endpoint into a source profile only after deterministic parity shows that it preserves the target-bearing evidence required by the project adapter.

A CMS or platform family MUST NOT create a blanket routing rule merely because some members expose similar endpoints.

Example evidence from the Maistio Finland Factory pilot:
- 10 public WordPress page / REST pairs were compared;
- 7 preserved target-bearing content with strong page-token parity;
- 3 were unsuitable: one returned HTTP 401 and two returned almost-empty REST content;
- therefore WordPress REST is learned per verified domain/page pattern, not globally.

Cost is secondary to semantic sufficiency:
- a smaller endpoint with missing content is not an optimization;
- a semantically complete endpoint with only modest byte savings may still be useful;
- failed or thin structured endpoints fall back to the cheapest already-working route or review, not automatically to browser collection.

## Rights separation

Source authority, collection permission and publication permission are distinct concerns.

The shared layer consumes an explicit project-resolved acquisition rights state. It does not infer permission from labels such as first_party, open_data, review or internal_reuse.

Unknown rights fail closed.

## AI Company OS mapping

- Perception: source observations, normalization envelopes, source profile state.
- Decision: deterministic route + Jev only when ambiguity is material.
- Execution Plane: collection engine/provider adapter and bounded retries.
- Evidence: raw response, extraction evidence when different, hashes, method, source identity, timestamps and validation outcomes.
- Learning: update source profiles only from verified run history and target-bearing parity.

The acquisition layer does not become a second source of truth.
