# CityOS

## Goal
Build a city-level operating system for managing services, data and decision flows.

## Core Identity
- CityOS = operational system
- Handles execution, data flows and services
- Separate from Pertti (which supervises)

## Architecture Principles
- scalable
- modular
- service-oriented
- governance-aware
- extensible

## Current Phase
Concept / early architecture

## Completed
- Initial concept defined
- Relationship with Pertti clarified

## Next
- Define core domains
- Define system boundaries
- Define service architecture
- Define data flows

## Constraints
- must scale across cities
- must support governance layer
- must integrate with external systems later
- must remain modular

## Notes
CityOS is the execution layer. Pertti supervises it but does not replace it.
# CityOS

## Mission
CityOS is a deterministic, observable, and operable system for ingesting, normalizing, and delivering city-level event data.

It is not just a data pipeline, but a system that can describe, debug, and operate itself through a structured knowledge layer.

## System Role
CityOS consists of three tightly connected layers:

- Engine
  - ingest pipeline
  - canonical model
  - snapshot builder
  - public API

- Control Plane
  - Lovable-based admin UI
  - source management
  - operations and debugging

- Knowledge Runtime
  - GitHub-based documentation (docs/cityos)
  - synced to system_documents via system_document_sources
  - rendered in UI

## Scope
- Event ingestion and normalization
- Canonical event modeling
- Snapshot generation for frontend consumption
- Public API delivery
- Operational control plane
- Documentation as system layer

## Out of Scope (for now)
- Full automation (linting, validation, auto-registration)
- Complex multi-city scaling features
- AI-driven decision layers inside core pipeline

## Architecture Principles
- Deterministic: same input → same output
- Observable: every step must be inspectable
- Safe to operate: changes must not break the system
- Docs are part of the system, not external
- GitHub is the source of truth for knowledge
- UI reflects system state, not guesses

## Current Phase
Foundation complete:
- Docs pipeline working
- Domain structure established
- Knowledge runtime operational

Transition phase:
→ Moving into system definition via Canonical Event Model

## Priorities
1. Canonical Event Model v1
2. Contracts layer expansion
3. Snapshot Builder refinement
4. Docs → Ops UI integration
5. Automation (later)

## Operating Rules
- One step at a time
- Do not break ingest runner
- Prefer smallest safe change
- Investigate before modifying
- Document all new structures immediately

## Status
- Active development
- System stable
- Ready for core model definition

## Last Updated
2026-03-25
