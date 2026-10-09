# Office reader release — 2026-10-09

Owner requested continuation of Meterion Office with Maistio, Far by Rail and Calendar Platform plus FI/FR/DE/SE products.

Applied existing office_project_ownership_v1 additive migration. Readback: exactly 21 existing projects assigned to the existing Meterion organization; no project or product duplicates created. Existing owner membership and organization both active. Deployed control-room-owner-bridge-v1 v4 with index.ts, unchanged current-owner.mjs and office-portfolio.mjs. Existing custom signature/issuer/audience/current-owner authentication retained, verify_jwt=false as in v3. Local Node tests: 31/31 pass. Unauthenticated real HTTP request to get_office_portfolio returns 401 owner_session_required.

Frontend exact commit 4b37c98e30eb22c67b884cb7ddf1d1a8601cb9fe submitted to existing Vercel project prj_xrVzWdvmC1s7X9IBG4rfFwjrhOjK, team team_YwCvYyzJI1EnunmdTekjJcT9. Preview deployment dpl_C1zxCdHvFU1CoFhDpmJisGWosBE3, https://ai-company-os-ceo-dashboard-kaibbjn11.vercel.app/office/ . Browser redirects to Vercel login. Real authenticated Office data rendering remains unverified; no session fabricated or protection removed.

No production frontend promotion, snapshot retirement, scheduler or new worker. Next: legitimate Vercel and app sign-in, verify three initial projects and four Calendar children, all-project switch, refresh and logout. Keep previous snapshot readers until successful live acceptance. Existing v3 code differs only by removal of Office-specific import/action/case and remains recoverable from prior branch commit and deployment history.
