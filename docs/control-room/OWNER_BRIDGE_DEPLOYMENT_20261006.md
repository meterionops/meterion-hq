# Authorized Office preview and Control Room bridge deployment

Checked 2026-10-06. Milestone 2 remains BLOCKED; not VERIFIED.

## Authorization and deployed sources
User explicitly approved latest Office preview publication, PR44 deployment to Control Room, bounded login/access-isolation verification, rollback if needed, and saving results.
Office preview: https://ai-company-os-ceo-dashboard-lma2mzd9i.vercel.app/office/
Vercel deployment dpl_9KzVFgZoJW5h7K3imNAT1i18PcCP READY, preview target null, exact commit 6ace3aab4b58a4b963f0b30e75a2f78f860ea3ce. Already auto-built; verified exact source instead of creating duplicate deployment. No production application promotion.

PR44 executable source: 319643680d00e3d305f56b20b673534de8a742ca in meterionops/meterion-hq. index.ts and current-owner.mjs deployed to cavvdvxicadgfftbziao/control-room-owner-bridge-v1. ACTIVE version 3, artifact hash 7ccf6e218525c956d997cbb86313af4328edb3354e24f8f0c49dde53518b129b. Readback contents match candidate files exactly. Existing custom Company JWT validation and verify_jwt=false preserved; identity, current active owner membership and active organization rechecked each request before admin RPC.

## Verification
22 PR44 Node behavioral/handler tests PASS. These use mocks and do not prove real authenticated upstream behavior.
Live POST without Authorization: 401 owner_session_required; request f0282fff-629a-4312-8754-afa44e5c08ed.
Live POST invalid non-secret test token: 401 owner_session_required; request c313b49a-da7e-45a6-8db6-88575640fa54.
Live GET: 405 method_not_allowed; request 68721686-a12a-4f71-8a0e-cd598c90b3ad.
OPTIONS for preview and example.com both returned 204 and wildcard CORS at hosted gateway. This does not prove application-origin filtering; not a substitute for JWT isolation. No new CORS claim or protection change.

## Remaining blocker
Preview redirects to Vercel sign-in. Secure browserAuth request timed out and runtime/tab reset. Fresh preview navigation again showed Vercel login; no positive authenticated signal. No application credentials or session tokens read/extracted. Actual owner-success, direct-link/refresh/shared logout/expiry and real revoked/foreign membership cases remain unverified. Owner's membership/organization were not changed.
Next: complete Vercel sign-in and application sign-in through secure authentication or supported manual handoff; then test the approved preview and deployed bridge with legitimate sessions. Do not mark milestone2 VERIFIED from unit tests or unauthenticated denials.

## Rollback
Before deployment, live version2 source preserved at https://github.com/meterionops/meterion-hq/blob/e5015cc9898e2dfdfaa39bfb0974192c4771cc17/docs/rollback/control-room-owner-bridge-v1-v2-20261006.ts . Previous artifact hash 7946f134fe79660a82fa3d5ce47cda42ddcc3a04a30fddbd82cfe986b4a45747.
Recovery: redeploy that file as index.ts with same project/function and existing verify_jwt=false; readback source and test live deny/owner access. This creates a newer deployment version. Rollback not triggered: no observed deployed runtime error or access leak; positive auth acceptance remains blocked. Do not revert security hardening merely for the browser login timeout.

## Durable state
This report is the evidence source for the authorized canonical checkpoint from v27 and tracking Page/Master update. PR341/PR44 remain unmerged; milestone3 is not completed by this deployment.
