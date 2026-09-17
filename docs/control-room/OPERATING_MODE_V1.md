# Meterion Control Room — Operating Mode v1

Status: OWNER CONFIRMED / IMPLEMENTED 2026-09-17

`operating_mode` is separate from portfolio class and lifecycle.

Portfolio class answers strategic importance. Lifecycle answers whether a project is active/paused/unconfirmed. Operating mode answers what kind of work the project currently is.

Allowed values:

- `build`
- `operate`
- `idea`
- `delivery`
- `paused`
- `system`
- `unconfirmed` — safe default for a newly registered identity until Owner/source evidence assigns the work mode

The Projects surface prioritizes this distinction because published/live operation is different work from product construction.

## UI rule

Projects uses work-mode tabs so published products do not compete with active construction work for attention:

- **Build** is the default tab and contains active `build` projects, grouped by portfolio class.
- **Published** contains active `operate` projects and keeps each project's portfolio-class badge.
- **Other** contains idea-stage, delivery and other unconfirmed work-mode states that should remain visible without crowding Build.

The selected tab is preserved while opening a project detail and returning to Projects during the same session.

Idea-stage projects remain quiet until explicitly activated. Delivery work stays distinct from software build work. Paused projects stay out of normal active views.

## Initial operating baseline

Published/operating:

- Calendar Platform
- Yritystiedot
- Nordic Bottle Index
- Korvauskirje
- Lomakone

Build:

- AI Company OS
- Maistio
- Cala Europe
- Sprinkler RFQ Platform
- Rail Atlas / Junamatkailusivusto
- Folio
- House of Flores
- Fire Sprinkler Hub

Fire Sprinkler Hub remains in build mode even though a public frontend exists: its canonical catalog is still in draft/review state, so the dominant work remains construction and verification rather than routine operation.

Idea:

- Microapps Factory
- Foreign Contractor Finland

Delivery:

- Sprinkler Water Tank — site delivery / compliance

Paused:

- Volaire
- Pelovio
- Avoinna
- Digiapu247

System:

- Meterion Control Room
