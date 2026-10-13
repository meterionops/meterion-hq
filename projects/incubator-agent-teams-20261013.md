# Incubator agent teams — 13 October 2026

User correction: maintenance must show an acting team with proposals, analysis, decisions, execution and verification. The old maintenance table is replaced by two team workspaces, six role seats, a workbench, real graph stages, artifact and history. All 14 brand briefs and 7 miniapp briefs remain canonical in existing Office connection metadata.

## Implemented scope

Owner-triggered `run_incubator_team_cycle` on the existing owner bridge. The unchanged signed JWT and current owner-membership checks run before this action. Project identity and organization are independently validated for the two existing candidate projects. No second auth session or credentials in the browser.

One cycle per group and UTC day; duplicate/concurrent claims use existing PER graph contract/idempotency. Six real nodes: observe, propose, analyse, decide, execute, verify. Proposer and analyst use separate bounded `provider-runtime-v1` calls in AI Company OS; both use the registered analysis provider. The decision role is deterministic policy, not a claimed Jev or independent model. The executor can only save a proposed internal build packet to the existing work unit. Original plans and other metadata are preserved. Scope, immutable source brief, analysis approval and graph prerequisites are checked again in the save RPC. Verifier reads the artifact back. Failure stays visible in the actual graph nodes.

Two maximum provider calls per cycle; existing provider profile per-call limits apply. No tool-enabled general building, deployment, customer messaging, payments, ads, or product launch in this cycle. Artifacts remain proposed; successful persistence verification is not product acceptance.

## Actual autonomy status

The six-hour deterministic readiness cron already exists and remains unchanged. An AI cycle runs server-side after the owner initiates it, without per-stage approval. No unattended AI schedule has been activated. A dedicated server worker identity and project/AOU capability binding are still required; never store or schedule a user bearer token. UI states this explicitly. No providers or agents are labelled as continuously running without evidence.

## Verification

- Module tests: complete chain, exact two calls, daily replay, analyst rejection, provider failure, changed source, readback failure, safe projection, escaping.
- Database integration: six graph transitions, guarded artifact save, completion, all rolled back; no QA rows remain.
- Real-source browser fixture: 21 briefs, 12 role seats, action request and failed-action feedback; no JS errors or page overflow at 1280, 375 or 320 pixels.
- Unauthorized read and run requests both return 401. Artifact RPC executable only by service_role, not anon/authenticated.
- Owner-authenticated real provider execution remains unverified: no owner session is available in this working environment. Test provider responses were fixtures; no fabricated production runtime history was inserted.

Backend: Control Room `cavvdvxicadgfftbziao`, owner bridge v14. Provider runtime remains in `yokcfxcbomuaupxxxoha`. Source/provider credentials were not retrieved or copied.
