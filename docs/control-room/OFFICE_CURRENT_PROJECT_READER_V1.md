# Meterion Office current project reader

7 October 2026. IMPLEMENTED / TESTED, not activated or fully VERIFIED.

## Result

Office project list, detail, decisions and rhythm read the current canonical Control Room tracking surface through the existing shared-session Owner bridge. The old snapshot RPC is no longer called by the new frontend. On-open/manual-refresh reads only; no new scheduler, worker, event bus, second project register, credentials store or agent runtime.

One bounded endpoint uses three backend reads: organization-owned project IDs, canonical tracking records, and allowlisted connection enrichment. Existing project UUIDs, state versions, verification dates and four Calendar child identities/domain/DNS records are preserved. Connection metadata remains dated source evidence: this change does not turn it into live website/analytics telemetry. Shops remain unconnected and miniapps remain unbound.

## Access and ownership

The deployed PR44 signature/issuer/audience/current Auth user/current active Owner membership and organization checks stay intact. Only the existing Meterion Owner is accepted; no broader multi-tenant login rollout is claimed. The new read additionally selects projects by explicit organization_id. Ownership migration assigns only the 21 inspected UUIDs; new/unassigned projects have no default owner and are excluded. No name joins or guessed Company bindings. Source queries use exact counts and reject truncation, missing project coverage, duplicate IDs or incorrect child bindings. No arbitrary metadata passes through the enrichment mapper.

## Evidence

- 65 Node behavior tests PASS: existing shared-auth and commerce tests plus reader, route refresh, lock/in-flight response, source failure, current-owner handler, organization scope, metadata allowlist and identity tests.
- Static-copy build and changed JavaScript syntax PASS. Full hosted Git build is pending.
- Actual source read: 21 unique project IDs, all state versions and verification timestamps preserved by candidate mapper; four Calendar children and DNS preserved; Korvauskirje current v16 renders (old screenshot v12).
- Ownership DDL/backfill tested in rollback transaction: 21 owned, zero foreign; original schema restored.
- Existing canonical work-batch writer tested in rollback: tracking sees v29/changed next action; same batch replay is idempotent; stale-version attempt rejected. Original v28 restored and zero canary batches remain.
- Candidate code is not deployed. Mocked Auth/route tests and SQL rollback are not authenticated live browser acceptance or a Dot connector test.

## Release sequence and rollback

1. Export the existing private Office snapshot and preserve deployed bridge v3 (already tracked in PR44 deployment evidence). Preserve frontend 5f1c39c3 as rollback source.
2. Apply project-backend ownership migration; deploy bridge index.ts + current-owner.mjs + office-portfolio.mjs with existing verify_jwt=false wrapper configuration. Keep platform secrets untouched.
3. Publish the Office frontend from the exact reviewed source. Check hosted build and back-read deployed files.
4. With legitimate shared session, read all 21 projects and four children. Check foreign/revoked membership denial, direct links, refresh and logout/expiry. Record one real authorized canonical work-batch update and confirm it appears after Office refresh, without snapshot writes. Check conflict rejection and source errors.
5. Only after those checks and backup, set transaction-local meterion.office_live_acceptance=VERIFIED and apply Company-backend snapshot retirement migration. Do not apply retirement before live acceptance. It removes only the old reader functions/private dated table, not canonical projects or history.
6. On failure before retirement, restore bridge v3 + frontend 5f1c39c3. Ownership column may remain with explicit assignments; it does not authorize execution. After retirement restore exported snapshot/schema only if rollback is needed.

## Remaining acceptance

Owner approval for the new database/production service release; exact hosted release; real authenticated read/write-to-Office proof; retirement of backed-up snapshot. Shared-session milestone2 acceptance remains open. Typed Company/global project mappings remain explicitly unbound, not inferred. No Dot or Shopify automation is activated.

