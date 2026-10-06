import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { hasCurrentOwnerAccess, OWNER, ORGANIZATION } from './current-owner.mjs';
const source = (await readFile(new URL('./index.ts', import.meta.url), 'utf8')).replace(/^import .*;\n/gm, '').replace('export default {', 'globalThis.handler = {');
const js = stripTypeScriptTypes(source);
for (const allowed of [false, true]) test(`handler ${allowed ? 'allows current owner' : 'denies revoked owner before admin RPC'}`, async () => {
  let rpcCalls = 0, lookups = 0;
  const context = vm.createContext({
    URL, Response, Headers, TextEncoder, crypto,
    createRemoteJWKSet: () => ({}),
    jwtVerify: async () => ({ payload: { sub: OWNER, app_metadata: { organization_id: ORGANIZATION, workspace_role: 'owner' } } }),
    hasCurrentOwnerAccess: (token, id) => hasCurrentOwnerAccess(token, id, async (url) => {
      lookups++;
      if (url.includes('/auth/')) return Response.json({ id: OWNER });
      if (url.includes('organization_members')) return Response.json(allowed ? [{ organization_id: ORGANIZATION, user_id: OWNER, role: 'owner', status: 'active' }] : []);
      return Response.json([{ id: ORGANIZATION, status: 'active' }]);
    }),
    withSupabase: (_, fn) => fn,
  });
  vm.runInContext(js, context);
  const response = await context.handler.fetch(new Request('https://bridge.test', { method: 'POST', headers: { authorization: 'Bearer signed-test-token' }, body: JSON.stringify({ action: 'get_today' }) }), { supabaseAdmin: { rpc: async () => { rpcCalls++; return { data: {}, error: null }; } } });
  assert.equal(response.status, allowed ? 200 : 401);
  assert.equal(rpcCalls, allowed ? 1 : 0);
  assert.equal(lookups, allowed ? 3 : 2);
});
