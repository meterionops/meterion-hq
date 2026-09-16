# Meterion Control Room — Security Hardening v1

Status: LIVE / OWNER BOOTSTRAP PENDING
Date: 2026-09-13

## Security objective

Control Room must fail closed. Knowing a URL, obtaining a normal Supabase account, or authorizing an arbitrary OAuth client must not grant access.

Access to MCP requires all of the following at the same time:

1. a valid, unexpired Supabase OAuth access token;
2. an explicit active row in `control_room_operators`;
3. an explicit active OAuth client row in `control_room_oauth_clients`;
4. AAL2 (`aal=aal2`) when the operator requires MFA;
5. access through the bounded Control Room MCP tool surface.

Owner-controlled project identity/classification remains outside MCP operational writes.

## Identity bootstrap

Normal sign-in begins only for emails pre-approved in `control_room_login_allowlist`.

The authorization UI performs the allow-list check server-side before requesting a magic link. After first-factor authentication, it re-validates the authenticated user email against the same allow-list.

TOTP MFA is required by default. New users enroll a TOTP factor; returning users must challenge an existing verified factor. OAuth consent is displayed only after the browser session reaches AAL2.

Creating an Auth user is not enough to obtain Control Room access. The resulting user ID must also be enrolled explicitly in `control_room_operators`.

## OAuth client binding

`control_room_oauth_clients` is a private server-side allow-list of client IDs.

The MCP token verifier rejects otherwise-valid user tokens when their OAuth `client_id` is not active in this table.

Current approved client:

- `76cf7884-1104-4b15-98c3-866a11232047` — ChatGPT – Meterion Control Room

The compatibility facade no longer advertises a dynamic registration endpoint and `/oauth/register` fails closed. Supabase may retain its server-level DCR setting during integration testing, but a dynamically created client cannot access Control Room unless its client ID is explicitly allow-listed. DCR should be disabled in Supabase after the stable ChatGPT integration is proven if it is no longer needed.

## Database boundary

All Control Room state/security tables have RLS enabled and intentionally expose no `anon` or `authenticated` table policies.

The browser and ChatGPT never receive the Supabase service-role key.

Control Room RPC execution remains server-side. Current architecture intentionally produces Supabase `RLS Enabled No Policy` INFO notices because these tables are private server-side surfaces rather than user-facing Data API tables.

## MCP audit

`control_room_mcp_audit_log` stores a bounded audit trail:

- timestamp;
- authenticated user ID;
- approved OAuth client ID;
- tool name;
- project key when present;
- HTTP result/outcome;
- bounded non-secret metadata.

Authentication denials record a reason such as:

- `operator_not_enrolled`;
- `oauth_client_not_approved`;
- `mfa_required`;
- `incomplete_token`.

Never store bearer tokens, refresh tokens, authorization codes, TOTP secrets, raw request bodies or project source payloads in the audit table.

## Compatibility facade

Public endpoint: `https://meterion-control-room-oauth-compat.onrender.com/mcp`

The Render facade is a protocol compatibility layer only. It does not hold a Supabase service-role key and does not authorize users itself.

Hardening:

- fixed canonical public origin rather than trusting arbitrary forwarded host values;
- unexpected host rejected;
- root OAuth and RFC 9728 protected-resource discovery only;
- S256 PKCE advertised;
- dynamic client registration disabled at the facade;
- unauthenticated `/mcp` requests return 401;
- simple per-IP rate limiting for tokenless MCP probes;
- request-body size cap;
- security headers;
- bearer token forwarded only to the trusted Supabase MCP upstream.

## Current fail-closed bootstrap state

At the post-hardening live verification:

- approved active OAuth clients: 1;
- active login emails: 0;
- active Control Room operators: 0;
- Supabase Auth users: 0;
- MCP audit rows: 0.

Therefore nobody — including the Owner — can currently access Control Room. The next explicit Owner action is to choose the first allowed login email. After that identity authenticates and completes TOTP enrollment, its newly created Auth user ID can be enrolled as the first `owner` operator.

## Remaining production-hardening after the first end-to-end proof

1. Disable Supabase Dynamic OAuth Apps if no longer required by ChatGPT.
2. Verify OAuth refresh preserves the required client binding and AAL policy.
3. Exercise negative tests: wrong client ID, non-allow-listed email, AAL1 token, non-operator token, stale token, missing bearer token.
4. Confirm audit rows are written without sensitive values.
5. Review token/session lifetimes and operator-revocation procedure.
6. Keep PRs unmerged until the first `jatka Maistiota` resume-anywhere round trip succeeds.
