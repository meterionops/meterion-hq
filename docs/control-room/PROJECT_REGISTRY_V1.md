# Meterion Control Room — Project Registry v1

Status: OWNER-CONFIRMED BASELINE / RUNTIME SYNCED
Owner decision dates: 2026-09-12, 2026-09-16 and 2026-09-17
Registry sync date: 2026-09-17

## Purpose

Define the top-level Meterion work domains that Control Room may track. This is not a task tracker and not the AI Company OS company registry.

Control Room should know only what is needed to answer:

- what are we building or operating?
- why does it exist?
- where are we now?
- what should happen next?
- is Founder attention required?

Actual work remains in ChatGPT / Work, GitHub, Supabase, Lovable, production services and other source systems.

## Hard boundaries

1. AI Company OS remains a separate product and domain.
2. Meterion projects created outside AI Company OS are not imported as AI Companies.
3. AI Company OS appears in Control Room as one top-level system/project surface; its internal AI Companies remain inside AI Company OS.
4. A GitHub repository is not automatically a Control Room project.
5. Project identity, lifecycle, portfolio class and operating mode are Owner-controlled.
6. AI may update operational state, but may not silently change the project's goal, portfolio class, lifecycle, operating mode or locked constraints.
7. Meterion Control Room is system infrastructure and does not consume a portfolio slot.
8. Pertti and CityOS are historical projects, not current portfolio projects, unless explicitly reactivated later.
9. Fire Sprinkler Hub and Sprinkler RFQ Platform are separate products and must never be merged into one Control Room identity.
10. Microapps Factory is idea-stage only until explicitly activated; its planned AI Company OS relationship does not make it an existing AI Company or active AI Company OS subsystem.
11. Foreign Contractor Finland is idea-stage despite having a Sites prototype; the prototype must not be treated as proof of an active production product.
12. Published/operating status is a separate dimension from portfolio class. A published product may still be CORE, AUTOPILOT, MAINTENANCE or UNCONFIRMED.

## Owner decisions

Current authority is the combination of:

- `OWNER_RECONCILIATION_PROPOSAL_V1.md` — OWNER CONFIRMED / 2026-09-12
- `OWNER_RECONCILIATION_V2.md` — OWNER CONFIRMED / 2026-09-16
- `OWNER_RECONCILIATION_V3.md` — OWNER CONFIRMED / 2026-09-16
- `OWNER_RECONCILIATION_V4.md` — OWNER CONFIRMED / 2026-09-17

Where they differ, the newer explicit decision wins.

### CORE

- AI Company OS
- Maistio
- Cala Europe
- Sprinkler RFQ Platform
- Rail Atlas / Junamatkailusivusto

The earlier `CORE max 3` rule is not a hard constraint for Control Room. The current Owner-confirmed CORE set contains five projects and is valid. Capacity rules may be advisory/configurable later, but may not override explicit Owner classification.

### EXPERIMENT

- Folio

### AUTOPILOT

- Calendar Platform
- Yritystiedot
- Nordic Bottle Index

### MAINTENANCE

- House of Flores
- Sprinkler Water Tank — site delivery / compliance, after closeout

### VAULT / paused

- Volaire
- Pelovio
- Avoinna
- Digiapu247

### Active / portfolio class unconfirmed

- Fire Sprinkler Hub
- Korvauskirje
- Lomakone

### Idea stage / classification unconfirmed

- Microapps Factory
- Foreign Contractor Finland

### Historical / no longer current

- Pertti
- CityOS

Tinku Latin Flavors and Namorada were explicitly removed from Control Room and are not retained as current or historical Control Room projects.

---

# Current registry

`Operating mode` is independent of portfolio class and lifecycle:

- `build` = construction/product-development work
- `operate` = published/live operation and upkeep
- `idea` = idea/prototype stage
- `delivery` = non-software delivery/compliance work
- `paused` = intentionally paused
- `system` = Control Room/system infrastructure

| Key | Name | Kind | Portfolio | Lifecycle | Operating mode | Notes |
|---|---|---|---|---|---|---|
| `meterion-control-room` | Meterion Control Room | internal_system | SYSTEM | active | system | Lightweight coordination layer; no task-manager expansion |
| `ai-company-os` | AI Company OS | internal_system | CORE | active | build | Company Factory remains canonical AI Company creation path |
| `maistio` | Maistio | product | CORE | active | build | Restaurant-first Local Discovery Graph; later verticals stay out of launch scope |
| `cala-europe` | Cala Europe | product | CORE | active | build | Europe-first beach discovery; core must not depend on paid content/data APIs |
| `sprinkler-rfq-platform` | Sprinkler RFQ Platform | product | CORE | active | build | Tank/RFQ operating domain; separate from Fire Sprinkler Hub |
| `rail-atlas` | Rail Atlas / Junamatkailusivusto | product | CORE | active | build | Global train-travel discovery product |
| `folio` | Folio | product | EXPERIMENT | active | build | Reality-engine / competitor-monitoring proof |
| `calendar-platform` | Calendar Platform | platform | AUTOPILOT | active | operate | Published/live localized calendar network; operating quality and expansion work |
| `yritystiedot` | Yritystiedot | data_asset | AUTOPILOT | active | operate | Published Finnish company-data product; recurring data operation |
| `nordic-bottle-index` | Nordic Bottle Index | product | AUTOPILOT | active | operate | Published Nordic price-comparison product; recurring source/data operation |
| `house-of-flores` | House of Flores | client_operation | MAINTENANCE | active | build | Client SEO/Timma presence and current website refinement |
| `sprinkler-water-tank-site` | Sprinkler Water Tank — site delivery / compliance | client_operation | MAINTENANCE | unconfirmed | delivery | Class is Owner-confirmed; lifecycle stays unconfirmed until current site-delivery/closeout evidence proves active vs completed |
| `fire-sprinkler-hub` | Fire Sprinkler Hub | product | UNCONFIRMED | active | build | Public frontend exists, but the canonical product state is still a draft/verification build backlog rather than routine operation |
| `korvauskirje` | Korvauskirje | product | UNCONFIRMED | active | operate | Published flight-compensation claim-letter product; portfolio class not yet assigned |
| `lomakone` | Lomakone | product | UNCONFIRMED | active | operate | Published travel-planning and destination-discovery product; portfolio class not yet assigned |
| `microapps-factory` | Microapps Factory | candidate | UNCONFIRMED | unconfirmed | idea | Idea-stage factory planned to connect with AI Company OS later; not an active build yet |
| `foreign-contractor-finland` | Foreign Contractor Finland | candidate | UNCONFIRMED | unconfirmed | idea | Idea-stage project with an existing ChatGPT Sites prototype; not an active build yet |
| `volaire` | Volaire | product | VAULT | paused | paused | Airport-specific discovery / SEO / affiliate product |
| `pelovio` | Pelovio | product | VAULT | paused | paused | Country-manual/travel-guide product; distinct from Volaire |
| `avoinna` | Avoinna | product | VAULT | paused | paused | Finland-wide opening-hours discovery |
| `digiapu247` | Digiapu247 | product | VAULT | paused | paused | AI phone-agent / digital-help service |

## Published / operating baseline

The following projects are currently source-verified as published/live and are represented as `operate`, not generic build work:

- Calendar Platform
- Yritystiedot
- Nordic Bottle Index
- Korvauskirje
- Lomakone

`Fire Sprinkler Hub` remains `build` for now. Its public Lovable frontend is live, but the current canonical product state still has the 172-family catalog in draft with review/data-quality work before the product is treated as operating-ready.

## Historical references only

| Key | Name | Current validity |
|---|---|---|
| `pertti` | Pertti | historical_only / retired_candidate |
| `cityos` | CityOS | historical_only / retired_candidate |

Older project files that say `Active` describe their state when those files were written; the latest explicit Owner decision is the current authority.

## Lifecycle interpretation used by runtime sync

The Owner-confirmed baseline treats EXPERIMENT, AUTOPILOT and MAINTENANCE entries as active unless a more specific Owner/source decision says otherwise, and treats the four VAULT entries as paused.

The exception is `sprinkler-water-tank-site`: its portfolio class is confirmed as MAINTENANCE, but current site/compliance evidence does not safely prove whether closeout has occurred. Its lifecycle remains `unconfirmed` rather than guessed.

`fire-sprinkler-hub` is active because a current repository, dedicated Supabase backend and public Lovable implementation are verified. Its portfolio class remains `UNCONFIRMED` until explicitly assigned, and its operating mode remains `build` until the catalog/publication gate is actually cleared.

`korvauskirje` and `lomakone` are active published operating products. Their portfolio classes remain `UNCONFIRMED` until explicitly assigned.

`microapps-factory` and `foreign-contractor-finland` remain `unconfirmed` / `idea` because they are explicitly idea-stage projects. A prototype does not automatically activate a project.

## Known project connections

- AI Company OS → `meterionops/ai-company-os`
- Sprinkler RFQ Platform → TankB2B Supabase `nekcogfryyhpmvumkrvt`
- Fire Sprinkler Hub → `meterionops/fire-sprinkler-hub`, Supabase `imzdpkekrdzjiqqpqbmk`, Lovable `861026d9-38b8-4d3e-bb05-250fc4ab1080`
- Microapps Factory → planned relationship to AI Company OS; no implementation source yet
- Foreign Contractor Finland → ChatGPT Sites prototype; exact prototype URL not yet connected to Control Room
- Korvauskirje → Supabase `tylxmwmqfrbfthrsnpwy`, Lovable `8234be17-972b-47db-a2a3-a0f686c6cee5`, `korvauskirje.fi`
- Lomakone → `meterionops/Lomakone`, Lovable `7e6a2022-a993-40d8-b5de-b8507f6346e8`, `lomakone.com`
- Volaire → `meterionops/volairport`
- Digiapu247 → `meterionops/digiapu247`
- Calendar Platform repo family → `meterionops/paivasta-selva`, `meterionops/kalenderklart`, `meterionops/calendify-your-world`, `meterionops/kalenderpunkt`
- Nordic Bottle Index repo family → `meterionops/nordic-bottle-index`, `meterionops/nordic-bottle-index-source`, `meterionops/nordic-bottle-index-v2`, `meterionops/nordic-bottle-compass`

A connection is not a project identity. Multiple repositories may belong to one project.

## Not top-level projects by default

Do not create separate top-level Control Room projects for:

- Maistio bars/nightlife/events verticals before they are explicitly activated
- individual Calendar Platform country sites
- individual AI Company OS AI Companies
- enrichment waves or other work batches
- Work runs
- GitHub branches or pull requests
- one-off data jobs

## Visibility rule

Projects should make the build-vs-operate distinction visible before task detail. Today should default to:

1. Owner-needed blockers and decisions
2. CORE projects with meaningful state changes
3. published/operating products only on material operational change or required action
4. other active projects only when they have a material change or require attention
5. background/autopilot systems only on anomaly, milestone or required action
6. historical-only projects never in normal portfolio views

Control Room should become quieter as the system works better.
