# Meterion Control Room — Owner Reconciliation v4

Status: OWNER CONFIRMED / 2026-09-17

This decision extends the current Control Room registry and project presentation model. Earlier Owner decisions remain valid except where this document explicitly supersedes them.

## Owner changes — 2026-09-17

### Remove Namorada entirely

`Namorada` is no longer a Control Room project.

- Remove it from the live registry.
- Remove it from Projects, Today and Resume Anywhere surfaces.
- Do not keep it as a historical-only Control Room project.
- Existing Git history may naturally retain older references, but current canonical docs/runtime must not list it.

### Published/operating is a separate project dimension

Portfolio class answers strategic importance. It does **not** answer whether a project is still being built or is already a published operating product.

Control Room therefore adds an Owner-controlled `operating_mode` dimension with these values:

- `build` — active construction/product-development work
- `operate` — published/live product whose work is primarily operation, upkeep, data/content refresh, reliability, monetization or incremental improvement
- `idea` — idea/prototype stage; no autonomous build unless explicitly activated
- `delivery` — non-software delivery/compliance work
- `paused` — intentionally paused/vaulted
- `system` — Control Room/system infrastructure

The Projects UI must make `operate` projects visibly distinct from build projects. Published/operating projects should appear in their own **PUBLISHED / OPERATING** section while retaining their portfolio-class badge.

## Operating-mode baseline

### PUBLISHED / OPERATING

Source-verified current published/operating products:

- Calendar Platform — AUTOPILOT
- Yritystiedot — AUTOPILOT
- Nordic Bottle Index — AUTOPILOT
- Korvauskirje — UNCONFIRMED portfolio class
- Lomakone — UNCONFIRMED portfolio class

These projects are not treated as generic build work. Their next actions should normally concern operating quality, freshness, reliability, conversion/monetization, maintenance or bounded product improvement.

### BUILD

Keep these in build mode for now:

- AI Company OS
- Maistio
- Cala Europe
- Sprinkler RFQ Platform
- Rail Atlas / Junamatkailusivusto
- Folio
- House of Flores
- Fire Sprinkler Hub

Fire Sprinkler Hub remains `build` despite having a publicly published Lovable frontend because its canonical current state still has all 172 product families in draft and an unresolved review/data-quality backlog; the primary work is still making the product publishable/trustworthy rather than routine operation.

### IDEA

- Microapps Factory
- Foreign Contractor Finland

### DELIVERY

- Sprinkler Water Tank — site delivery / compliance

### PAUSED

- Volaire
- Pelovio
- Avoinna
- Digiapu247

### SYSTEM

- Meterion Control Room

## Authority rule

For current Control Room identity, classification and operating mode, use Owner reconciliation documents in chronological order. This 2026-09-17 v4 decision is the newest authority for Namorada removal and the operating-mode model.
