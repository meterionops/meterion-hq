# Control Room Web v1 — Acceptance Record

Date: 2026-09-16
Status: ACCEPTED

The first Owner bootstrap completed successfully on the Render-hosted private UI.

Verified acceptance facts:

- 1 Supabase Auth user exists for the intended Owner identity.
- 1 active `control_room_operators` row exists with role `owner` and `require_mfa=true`.
- 1 TOTP MFA factor is verified.
- The browser session visibly reports `AAL2 · private`.
- Authenticated Today, Projects, AI Company OS and System views all render through the private gateway.
- Control Room state advanced to v24 with `founder_gate=none`, `founder_attention_required=false`, and `autonomy_state=can_continue`.

The browser-facing surface is `https://meterion-control-room-web.onrender.com/`. Render holds no Control Room service-role or source-system credentials; Supabase remains the authentication, authorization and private data boundary.

ChatGPT MCP remains independent of Web v1 acceptance.
