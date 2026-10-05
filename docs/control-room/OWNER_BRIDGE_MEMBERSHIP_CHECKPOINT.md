# Owner bridge current membership checkpoint

Milestone 2 remains BLOCKED, not VERIFIED.

Implemented on fix/owner-bridge-current-membership: preserve existing issuer/audience/signature and fixed owner/organization checks, then validate Auth user, RLS-visible active owner membership and active organization on every request. Five-second shared timeout; upstream failures deny; no positive authorization cache, no service key in the lookup.

Verification: Node 24 `node --test supabase/functions/control-room-owner-bridge-v1/*.test.mjs` passes 22 tests, including handler denial before administrative RPC, revoked/inactive/foreign/downgraded access and upstream failure. These use mocked Auth/REST and JWT verification; they are not deployed authentication or real signature/session tests.

Vercel now reports READY deployment dpl_Fs6wmVjCAqUshc4Qy14PGjTCrA71 at c14471a9f3a6fbba460c2a7d19c54c08ea7e87d2, https://ai-company-os-ceo-dashboard-8fnlxesxs.vercel.app . This supersedes the earlier missing-exact-source-build observation, but does not prove browser acceptance.

Live owner bridge remains version 2 (unmodified). Deploy this candidate only with an executable authorized session acceptance path; verify positive owner access and live revoked/inactive isolation. The browser-authentication navigation was previously rejected by automatic approval review as insufficiently scoped; this run has not bypassed that restriction or fabricated a session. Authenticated Home/Office navigation, refresh, expiry and cross-tab sign-out remain open. Milestones 3–7 remain planned; no production release.

Resume with a permitted authenticated preview session, deploy/validate bridge candidate, run shared session acceptance, then update canonical state. Do not label the milestone VERIFIED from these unit tests or deployment READY status.
