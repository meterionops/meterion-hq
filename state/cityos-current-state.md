# CityOS – Current State

## Phase
Concept / early architecture

## Completed
- Project placeholder created in HQ
- Initial goal captured

## Next
- Define core domains
- Define system boundaries
- Define current focus

## Constraints
- scalable
- modular
- governance-aware

## Notes
CityOS acts as a system layer above individual services.
# CityOS Current State

## Summary
CityOS has a working GitHub-backed documentation pipeline acting as a knowledge runtime.
Documentation is now structured by domain under docs/cityos and synced into Supabase for UI rendering.
System is stable and ready to move into Canonical Event Model v1.

## Working Now
- Docs pipeline: GitHub (.md) → system_document_sources → system_documents → UI
- Domain-based documentation structure under docs/cityos/
- Root index.md + domain index.md pattern working
- Docs rendering correctly in UI
- docs-authoring-guide.md defines frontmatter + naming standards

## Recently Completed
- End-to-end docs pipeline implemented
- system_document_sources configured for all docs
- Domain structure created:
  - architecture
  - models
  - contracts
  - specs
  - playbooks
  - onboarding
- Index pattern established for all domains
- Authoring standard locked

## Current Focus
- Move from documentation foundation → system definition
- Start defining core system contracts via docs

## Next Step
- Design and implement Canonical Event Model v1
  - event identity
  - canonical schema
  - merge logic
  - ingest → canonical contract

## Known Risks / Open Questions
- Canonical model not yet defined → blocks system consistency
- Contracts layer still thin → risk of implicit behavior
- Snapshot builder rules not fully explicit
- Docs not yet connected to operational UI

## Constraints
- Do not break ingest pipeline
- Maintain deterministic system design
- One change at a time
- All new structures must be documented immediately

## Last Updated
2026-03-25
