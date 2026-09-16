# Meterion Control Room — Owner Reconciliation v2

Status: OWNER CONFIRMED / 2026-09-16

This decision supersedes the 2026-09-12 baseline only where explicitly stated below. All other previously confirmed portfolio classifications remain unchanged.

## Owner changes — 2026-09-16

### Remove Tinku Latin Flavors entirely

`Tinku Latin Flavors` is no longer a Control Room project.

- Remove it from the live registry.
- Remove it from current portfolio/read-model surfaces.
- Do not keep it as a historical-only Control Room project.
- Existing Git history may naturally retain older references, but current canonical docs and runtime must not list it.

### Add Fire Sprinkler Hub as its own top-level project

`Fire Sprinkler Hub` is a distinct product from `Sprinkler RFQ Platform`.

Current verified implementation sources:

- GitHub: `meterionops/fire-sprinkler-hub`
- Supabase: `imzdpkekrdzjiqqpqbmk` (`Sprinkler Hub`)
- Lovable: `861026d9-38b8-4d3e-bb05-250fc4ab1080`

The product is a manufacturer-independent fire-sprinkler search, selection, comparison and verification platform for fire-protection professionals.

Its lifecycle is active because a current implementation, backend and published frontend exist. Its portfolio class remains `UNCONFIRMED` until the Owner explicitly assigns CORE / EXPERIMENT / AUTOPILOT / MAINTENANCE / VAULT.

Hard boundary:

- `Fire Sprinkler Hub` must not be conflated with `Sprinkler RFQ Platform`.
- The `meterionops/fire-sprinkler-hub` repository and Fire Sprinkler Hub Lovable frontend belong to Fire Sprinkler Hub, not to Sprinkler RFQ Platform.
- Sprinkler RFQ Platform keeps its separate TankB2B operating source unless a separate RFQ-specific repository/frontend is later verified.

### Add Microapps Factory as an idea-stage project

Add `Microapps Factory` to the Control Room registry.

Current status:

- idea stage only;
- no active build yet;
- intended to be built in connection with AI Company OS at a later stage.

Runtime representation:

- kind: `candidate`
- portfolio class: `UNCONFIRMED`
- lifecycle: `unconfirmed`
- autonomy: inactive until explicitly activated

Control Room should retain a planned relationship to AI Company OS, but must not represent Microapps Factory as an existing AI Company, active factory or implemented AI Company OS subsystem before that work actually exists.

## Current portfolio after this decision

### CORE

- AI Company OS
- Maistio
- Cala Europe
- Sprinkler RFQ Platform
- Rail Atlas / Junamatkailusivusto

### EXPERIMENT

- Folio

### AUTOPILOT

- Calendar Platform
- Yritystiedot
- Nordic Bottle Index

### MAINTENANCE

- Namorada
- House of Flores
- Sprinkler Water Tank — site delivery / compliance, after closeout

### VAULT / paused

- Volaire
- Pelovio
- Avoinna
- Digiapu247

### Active, portfolio class not yet confirmed

- Fire Sprinkler Hub

### Idea stage / classification not yet confirmed

- Microapps Factory

### Historical only

- Pertti
- CityOS

## Authority rule

For current Control Room identity and classification, use this document together with the 2026-09-12 decision. When the two differ, this 2026-09-16 decision is newer and wins.