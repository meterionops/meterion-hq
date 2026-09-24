# Project adoption

## Maistio

Use first. Replace project-specific transport/routing duplication with the shared layer while keeping restaurant/menu parsers and Local Discovery Graph writes in Maistio.

Pilot acceptance:
- one first-party static menu source
- one public structured/XHR source
- one JS-rendered source
- raw snapshot/hash retained
- deterministic failures classified
- Jev used only for an ambiguous route/change cohort
- no regression in existing candidate-source-link evidence semantics

## Calendar Platform

Use for source acquisition/provenance only. Country-specific official source adapters and calendar canonical facts remain Calendar Platform-owned.

## Cala Europe

Use for verified public practical-source acquisition and refresh. Beach identity, decision graph, image rights and source authority remain Cala-owned.

## Nordic Bottle Index

Candidate later migration target because it already has bounded crawlers and Playwright collectors. Do not replace working source-specific logic until parity tests exist.

## Sprinkler Hub / regulated evidence

Adopt only for sources whose rights gate permits automated collection. Source-rights decisions remain project-specific and fail closed.
