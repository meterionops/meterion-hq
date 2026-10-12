# Digital Studio — Projektihautomo

Recorded 2026-10-12 at the owner's request. Source discussion: **Digitaalisen tuotteen myynti**, 2026-10-12. The seven brand concepts and proposed product ranges are recorded in `digital-studio.json`. They are planning material, not launched products or approved execution jobs. Väljä's complete-bundle price was not recovered and remains unspecified.

## Canonical state

- Control Room project: `digital-studio`, ID `a856b823-6520-40e2-abca-067dcb93795e`.
- Supabase: `cavvdvxicadgfftbziao`.
- Classification: candidate, operating_mode idea, lifecycle unconfirmed, autonomy inactive.
- Content: `control_room_project_connections.metadata.office_incubator`, connection type chatgpt, external_ref `digital-studio-incubator-20261012`.
- The JSON is the initial accepted recording; subsequent Office content edits belong in the canonical database metadata.
- Office route: `/office/incubator`; nav **Projektihautomo**. These plans are excluded from the existing five-project portfolio.

## Brands

Tarjousvalmis; Kotikaava; Perheklik; Kaksinhetki; Päiväraami; Huomenvara; Väljä. Goals and audience descriptions summarize the source discussion. Product descriptions are concise summaries; prices are proposals.

## Delivery

The existing `control-room-owner-bridge-v1` reader exposes only the allowlisted incubator fields, after its unchanged current-owner and organization authorization gate. The existing schema is reused. No new worker, payment flow, public brand site, or execution schedule is created.

The accompanying reader source is based on deployed version 9, including the deployed `office-portfolio.mjs` and `current-owner.mjs` files that were absent from the main-branch function folder. Only the incubator projection is added; index/auth behavior is retained from deployment.

## Verification

- Seven brand records read back from canonical storage.
- Original and updated projections compared against current database data: all prior fields, Google summaries, and Stripe summaries identical.
- Parent binding, candidate binding, duplicate rejection, and field allowlisting checked.
- Actual Office route and nav tested in an isolated browser with a mocked authenticated data source: seven disclosures, product details, 390px layout without horizontal overflow, refresh failure retention, and sign-out clearing.
- No automatic promotion into active projects. The next product/business step remains a separate decision.
