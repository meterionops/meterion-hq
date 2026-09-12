# Meterion Control Room — Owner Reconciliation v1

Status: OWNER CONFIRMED / 2026-09-12

## Confirmed portfolio direction

The Owner explicitly confirmed the current CORE set as:

1. AI Company OS
2. Maistio
3. Cala Europe
4. Sprinkler RFQ Platform
5. Rail Atlas / Junamatkailusivusto

The earlier `CORE max 3` assumption is superseded for Control Room by this explicit Owner decision. Control Room must not raise a one-in-one-out conflict simply because these five are CORE.

Meterion Control Room itself is system infrastructure and sits outside the portfolio classification.

## Confirmed historical/non-current projects

The Owner stated that Pertti and CityOS no longer appear to be valid current projects.

Therefore:

- Pertti -> historical-only / retired candidate
- CityOS -> historical-only / retired candidate

Preserve their repositories, architecture documents and state history. Do not show them in Today or the active portfolio unless explicitly reactivated later.

Older project files that say `Active` describe their state when those files were written; the 2026-09-12 Owner decision is the newer authority for Control Room.

## Current visible portfolio baseline

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
- Tinku Latin Flavors
- House of Flores
- Sprinkler Water Tank site delivery after closeout

### VAULT / paused

- Volaire
- Pelovio
- Avoinna
- Digiapu247

### Historical only

- Pertti
- CityOS

Secondary classifications may be refined later, but they must not block Control Room implementation. The five-project CORE set and Pertti/CityOS retirement direction are canonical Owner decisions.

## Product implication

Control Room must optimize for a portfolio with more than three CORE projects. It should not enforce arbitrary numeric class limits in the data model.

Portfolio policy checks should therefore be advisory and configuration-driven, never hard schema constraints.

The primary prioritization question becomes:

> Which Founder action, if any, most usefully advances the confirmed active portfolio right now?

not:

> Is the number of CORE projects under a hard-coded limit?

## Next implementation step

Proceed to the minimal persistence/read-model layer:

- project identity
- current project state
- material events
- source-system connections
- owner attention projection

No task tracker, sprint model or heavy project-management layer.