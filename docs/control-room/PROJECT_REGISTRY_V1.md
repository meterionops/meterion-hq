# Meterion Control Room — Project Registry v1

Status: OWNER-CONFIRMED BASELINE
Date: 2026-09-12

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

## Owner decisions — 2026-09-12

### Confirmed CORE

- AI Company OS
- Maistio
- Cala Europe
- Sprinkler RFQ Platform
- Rail Atlas / Junamatkailusivusto

The earlier `CORE max 3` rule is not a hard constraint for Control Room. The current Owner-confirmed CORE set contains five projects and is valid. Capacity rules may be advisory/configurable later, but may not override explicit Owner classification.

### Historical / no longer current

- Pertti
- CityOS

Preserve their repositories and historical architecture. Do not surface them in Today or the active portfolio unless the Owner explicitly reactivates them.

---

# Current registry

| Key | Name | Kind | Portfolio | Lifecycle | Notes |
|---|---|---|---|---|---|
| `meterion-control-room` | Meterion Control Room | internal_system | SYSTEM | active | Lightweight coordination layer; no task-manager expansion |
| `ai-company-os` | AI Company OS | internal_system | CORE | active | Company Factory remains canonical AI Company creation path |
| `maistio` | Maistio | product | CORE | active | Restaurant-first Local Discovery Graph; later verticals stay out of launch scope |
| `cala-europe` | Cala Europe | product | CORE | active | Europe-first beach discovery; core must not depend on paid content/data APIs |
| `sprinkler-rfq-platform` | Sprinkler RFQ Platform | product | CORE | active | Keep separate from individual sprinkler installation/client jobs |
| `rail-atlas` | Rail Atlas / Junamatkailusivusto | product | CORE | active | Global train-travel discovery product |
| `folio` | Folio | product | UNCONFIRMED | active | Active portfolio project; classification not confirmed here |
| `calendar-platform` | Calendar Platform | platform | UNCONFIRMED | unconfirmed | Country sites stay inside the platform family by default |
| `yritystiedot` | Yritystiedot | data_asset | UNCONFIRMED | unconfirmed | Shared Finnish company-data asset |
| `nordic-bottle-index` | Nordic Bottle Index | product | UNCONFIRMED | unconfirmed | Cross-Nordic product matching/indexing |
| `namorada` | Namorada | product | UNCONFIRMED | unconfirmed | Charter administration workflow |
| `tinku-latin-flavors` | Tinku Latin Flavors | client_operation | UNCONFIRMED | unconfirmed | Client website/reservation presence |
| `house-of-flores` | House of Flores | client_operation | UNCONFIRMED | unconfirmed | Client SEO/Timma presence |
| `volaire` | Volaire | product | UNCONFIRMED | unconfirmed | Airport-specific discovery / SEO / affiliate product |
| `pelovio` | Pelovio | product | UNCONFIRMED | unconfirmed | Country-manual/travel-guide product; distinct from Volaire |
| `avoinna` | Avoinna | product | UNCONFIRMED | unconfirmed | Finland-wide opening-hours discovery |
| `digiapu247` | Digiapu247 | product | UNCONFIRMED | unconfirmed | AI phone-agent / digital-help service |
| `sprinkler-water-tank-site` | Sprinkler Water Tank — site delivery / compliance | client_operation | UNCONFIRMED | completed_candidate | Preserve closeout history; never merge with RFQ Platform |

## Historical references only

| Key | Name | Current validity |
|---|---|---|
| `pertti` | Pertti | historical_only / retired_candidate |
| `cityos` | CityOS | historical_only / retired_candidate |

Historical files may contain older `Active` labels. The Owner decision dated 2026-09-12 is the current authority.

## Known project connections

- AI Company OS → `meterionops/ai-company-os`
- Sprinkler RFQ Platform → `meterionops/fire-sprinkler-hub`
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