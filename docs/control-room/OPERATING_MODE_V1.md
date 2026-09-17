# Meterion Control Room — Operating Mode v1

Status: DESIGN / OWNER CONFIRMED 2026-09-17

`operating_mode` is separate from portfolio class and lifecycle.

Portfolio class answers strategic importance. Lifecycle answers whether a project is active/paused/unconfirmed. Operating mode answers what kind of work the project currently is.

Allowed values:

- `build`
- `operate`
- `idea`
- `delivery`
- `paused`
- `system`

The Projects surface should prioritize this distinction because published/live operation is different work from product construction.

## UI rule

Active `operate` projects render in a dedicated **PUBLISHED / OPERATING** section and keep their portfolio-class badge.

Active `build` projects remain grouped by portfolio class.

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
