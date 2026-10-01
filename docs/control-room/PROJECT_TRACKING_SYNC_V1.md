# Meterion Control Room — Project Tracking Sync v1

Status: IMPLEMENTATION CANDIDATE  
Date: 2026-10-01

## Goal

Make project tracking a Meterion-wide derived surface rather than a collection of manually maintained tracking documents.

The rule is:

> Canonical project work updates Control Room once. Every tracking surface reads the same projection or consumes the same change feed.

This applies to every Meterion project registered in Control Room, not only AI Company OS.

## Ownership

Control Room remains the canonical coordination source for:

- Project identity/classification;
- current Project State;
- material project events;
- source-system connection pointers.

Project source systems remain authoritative for their detailed domain data.

Tracking surfaces are read models. They are never allowed to become a second Project State.

## Automatic path

```text
Meaningful project work
  -> complete_work_batch / Project State commit / material event
  -> Control Room canonical tables
  -> database trigger emits tracking change sequence
  -> control_room_project_tracking_v1 is immediately current
  -> consumer pulls snapshot or changes
  -> Meterion UI / future Office / external tracking adapter renders it
```

No project-specific synchronization logic is required.

## What changes automatically

The tracking projection changes after:

- a new Project State version;
- a material project event;
- a relevant Owner-controlled Project identity/classification change;
- a project connection change.

The projection includes:

- Project identity and portfolio/lifecycle/operating mode;
- current Project State and Project Control fields;
- state freshness;
- current build / definition of done / next gate;
- blocker and Founder-attention state;
- latest material event;
- up to 12 recent material events;
- up to 12 milestone-like material events;
- source connections already exposed by the existing project surface;
- a stable `tracking_fingerprint`;
- `tracking_changed_at`.

## Milestones

New work should mark milestone events explicitly with:

```json
{
  "metadata": {
    "tracking_class": "milestone"
  }
}
```

The projection also recognizes legacy event names ending in:

- `verified`
- `locked`
- `completed`
- `merged`
- `deployed`
- `activated`
- `live`

This compatibility heuristic exists only for historical Control Room events. New producers should use explicit metadata.

## Meterion-wide change feed

`control_room_tracking_change_feed_v1` is append-only.

A monotonic `sequence` makes it possible for a consumer to remember one cursor for the entire Meterion portfolio.

Consumers use:

`control_room_get_tracking_changes_v1(after_sequence, limit)`

Then fetch the fresh project snapshot with:

`control_room_get_project_tracking_v1(project_key)`

or refresh the whole/filtered surface with:

`control_room_get_project_tracking_surface_v1(...)`.

The feed stores coordination change metadata only. It does not copy project source data.

## Consumer modes

### Pull consumers

Preferred when possible.

Examples:

- AI Company OS Owner Projects;
- Meterion Office;
- project/operator dashboards;
- a future ChatGPT surface that can call the Owner bridge.

A pull consumer needs no push delivery state. It reads the canonical projection at render time.

### Push-only consumers

Some external documents/pages may not support runtime reads.

Those require a separate adapter that:

1. consumes the Meterion-wide change feed;
2. renders the canonical tracking projection;
3. updates the external destination;
4. persists its own delivery cursor/idempotency state.

The adapter is a delivery mechanism only. The external document never becomes authoritative.

## ChatGPT tracking Pages

The existing ChatGPT “— seuranta” Pages are currently static document surfaces from Control Room's perspective. Control Room has no supported server-side Page write API in this implementation.

Therefore this milestone deliberately does **not** pretend that a database trigger can mutate those Pages.

The correct boundary is now in place:

- Meterion-wide change detection and canonical tracking projection are automatic;
- AI Company OS / future Meterion Office can consume it directly;
- ChatGPT Page delivery requires a Page write/read adapter when such an authorized interface is available.

Until then, a Page can be reconciled from the canonical tracking endpoint, but it must not be treated as current truth merely because its visible text has not refreshed.

## Agent/Operator write rule

After meaningful autonomous work, the default write remains:

`control_room_complete_work_batch_v1`

It atomically:

- advances Project State;
- appends one material event;
- stores optional decision evidence.

This is the write that makes tracking automatically current.

Routine prompts, every API call and every commit must not create Control Room material events.

## New read contracts

- `control_room_get_project_tracking_v1(project_key)`
- `control_room_get_project_tracking_surface_v1(portfolio_class?, lifecycle_status?, changed_since?)`
- `control_room_get_tracking_changes_v1(after_sequence?, limit?)`

These are service-role-only database functions and are exposed through the authenticated Meterion Owner bridge.

## Security

- tracking feed is RLS-enabled;
- no anon/authenticated table access;
- only service role reads/writes the feed directly;
- tracking functions are service-role-only;
- no credentials or raw source-system payloads are copied;
- Owner-controlled fields remain Owner-controlled;
- tracking never expands execution authority.

## Acceptance

Tracking Sync v1 is complete when:

1. changing Project State for one project changes its tracking fingerprint automatically;
2. appending a material event appears automatically in recent events;
3. a second project is unaffected;
4. a Meterion-wide cursor returns the change without per-project polling;
5. existing Project State / events / source systems remain authoritative;
6. the Owner bridge exposes tracking reads;
7. AI Company OS and future Meterion Office can use the same contract;
8. no claim is made that a static external Page has updated unless an adapter actually delivered it.

## Next adapter work

The core does not depend on any one presentation surface.

Adapters may later be added for:

- ChatGPT Pages, if an authorized Page write API becomes available;
- Google Drive project-control documents;
- Slack/email briefs;
- external dashboards.

All adapters must consume the same Meterion-wide tracking projection/change feed.
