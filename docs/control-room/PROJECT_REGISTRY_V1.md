# Meterion Control Room — Project Registry v1

Status: OWNER-CONFIRMED BASELINE / RUNTIME SYNCED
Owner decision dates: 2026-09-12 and 2026-09-16
Registry sync date: 2026-09-16

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
5. Project identity, lifecycle and portfolio class are Owner-controlled.
6. AI may update operational state, but may not silently change the project's goal, portfolio class, lifecycle or locked constraints.
7. Meterion Control Room is system infrastructure and does not consume a portfolio slot.
8. Pertti and CityOS are historical projects, not current portfolio projects, unless explicitly reactivated later.
9. Fire Sprinkler Hub and Sprinkler RFQ Platform are separate products and must never be merged into one Control Room identity.
10. Microapps Factory is idea-stage only until explicitly activated; its planned AI Company OS relationship does not make it an existing AI Company or active AI Company OS subsystem.

## Owner decisions

Current authority is the combination of:

- `OWNER_RECONCILIATION_PROPOSAL_V1.md` — OWNER CONFIRMED / 2026-09-12
- `OWNER_RECONCILIATION_V2.md` — OWNER CONFIRMED / 2026-09-16

Where they differ, the 2026-09-16 decision is newer and wins.

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

- Namorada
- House of Flores
- Sprinkler Water Tank — site delivery / compliance, after closeout

### VAULT / paused

- Volaire
- Pelovio
- Avoinna
- Digiapu247

### Active / portfolio class unconfirmed

- Fire Sprinkler Hub

### Idea stage / classification unconfirmed

- Microapps Factory

### Historical / no longer current

- Pertti
- CityOS

Tinku Latin Flavors was explicitly removed from Control Room on 2026-09-16 and is not retained as a current or historical Control Room project.

---

# Current registry

| Key | Name | Kind | Portfolio | Lifecycle | Notes |
|---|---|---|---|---|---|
| `meterion-control-room` | Meterion Control Room | internal_system | SYSTEM | active | Lightweight coordination layer; no task-manager expansion |
| `ai-company-os` | AI Company OS | internal_system | CORE | active | Company Factory remains canonical AI Company creation path |
| `maistio` | Maistio | product | CORE | active | Restaurant-first Local Discovery Graph; later verticals stay out of launch scope |
| `cala-europe` | Cala Europe | product | CORE | active | Europe-first beach discovery; core must not depend on paid content/data APIs |
| `sprinkler-rfq-platform` | Sprinkler RFQ Platform | product | CORE | active | Tank/RFQ operating domain; separate from Fire Sprinkler Hub |
| `rail-atlas` | Rail Atlas / Junamatkailusivusto | product | CORE | active | Global train-travel discovery product |
| `folio` | Folio | product | EXPERIMENT | active | Reality-engine / competitor-monitoring proof |
| `calendar-platform` | Calendar Platform | platform | AUTOPILOT | active | Country sites stay inside the platform family by default |
| `yritystiedot` | Yritystiedot | data_asset | AUTOPILOT | active | Shared Finnish company-data asset |
| `nordic-bottle-index` | Nordic Bottle Index | product | AUTOPILOT | active | Cross-Nordic product matching/indexing |
| `namorada` | Namorada | product | MAINTENANCE | active | Charter administration workflow |
| `house-of-flores` | House of Flores | client_operation | MAINTENANCE | active | Client SEO/Timma presence and current website refinement |
| `sprinkler-water-tank-site` | Sprinkler Water Tank — site delivery / compliance | client_operation | MAINTENANCE | unconfirmed | Class is Owner-confirmed; lifecycle stays unconfirmed until current site-delivery/closeout evidence proves active vs completed |
| `fire-sprinkler-hub` | Fire Sprinkler Hub | product | UNCONFIRMED | active | Manufacturer-independent sprinkler search, selection, comparison and verification product |
| `microapps-factory` | Microapps Factory | candidate | UNCONFIRMED | unconfirmed | Idea-stage factory planned to connect with AI Company OS later; not an active build yet |
| `volaire` | Volaire | product | VAULT | paused | Airport-specific discovery / SEO / affiliate product |
| `pelovio` | Pelovio | product | VAULT | paused | Country-manual/travel-guide product; distinct from Volaire |
| `avoinna` | Avoinna | product | VAULT | paused | Finland-wide opening-hours discovery |
| `digiapu247` | Digiapu247 | product | VAULT | paused | AI phone-agent / digital-help service |

## Historical references only

| Key | Name | Current validity |
|---|---|---|
| `pertti` | Pertti | historical_only / retired_candidate |
| `cityos` | CityOS | historical_only / retired_candidate |

Older project files that say `Active` describe their state when those files were written; the latest explicit Owner decision is the current authority.

## Lifecycle interpretation used by runtime sync

The Owner-confirmed baseline treats EXPERIMENT, AUTOPILOT and MAINTENANCE entries as active unless a more specific Owner/source decision says otherwise, and treats the four VAULT entries as paused.

The exception is `sprinkler-water-tank-site`: its portfolio class is confirmed as MAINTENANCE, but current site/compliance evidence does not safely prove whether closeout has occurred. Its lifecycle remains `unconfirmed` rather than guessed.

`fire-sprinkler-hub` is active because a current repository, dedicated Supabase backend and published Lovable implementation are verified. Its portfolio class remains `UNCONFIRMED` until explicitly assigned.

`microapps-factory` remains `unconfirmed` / inactive at the operating-state level because only the idea and intended AI Company OS relationship are currently confirmed.

## Known project connections

- AI Company OS → `meterionops/ai-company-os`
- Sprinkler RFQ Platform → TankB2B Supabase `nekcogfryyhpmvumkrvt`
- Fire Sprinkler Hub → `meterionops/fire-sprinkler-hub`, Supabase `imzdpkekrdzjiqqpqbmk`, Lovable `861026d9-38b8-4d3e-bb05-250fc4ab1080`
- Microapps Factory → planned relationship to AI Company OS; no implementation source yet
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

Today should default to:

1. Owner-needed blockers and decisions
2. CORE projects with meaningful state changes
3. other active projects only when they have a material change or require attention
4. background/autopilot systems only on anomaly, milestone or required action
5. historical-only projects never in normal portfolio views

Control Room should become quieter as the system works better.
