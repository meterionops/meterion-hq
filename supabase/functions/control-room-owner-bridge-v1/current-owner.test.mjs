import { test } from 'node:test';
import assert from 'node:assert/strict';
import { hasCurrentOwnerAccess, OWNER, ORGANIZATION } from './current-owner.mjs';

const member = { organization_id: ORGANIZATION, user_id: OWNER, role: 'owner', status: 'active' };
const valid = () => [{ id: OWNER }, [{ ...member }], [{ id: ORGANIZATION, status: 'active' }]];
function fixture(results = valid()) {
  const calls = [];
  return { calls, fetcher: async (url, options) => {
    calls.push({ url, options });
    const result = results[calls.length - 1];
    if (result instanceof Error) throw result;
    return result instanceof Response ? result : Response.json(result);
  } };
}
test('active owner requires Auth plus current RLS membership and organization', async () => {
  const f = fixture();
  assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), true);
  assert.equal(f.calls.length, 3);
  for (const { url, options } of f.calls) {
    assert.ok(url.startsWith('https://yokcfxcbomuaupxxxoha.supabase.co/'));
    assert.equal(options.headers.Authorization, 'Bearer test-token');
    assert.ok(options.headers.apikey.startsWith('sb_publishable_'));
    assert.equal(options.cache, 'no-store');
    assert.equal(options.redirect, 'error');
    assert.ok(options.signal instanceof AbortSignal);
  }
});
test('foreign user rejected before any lookup', async () => {
  const f = fixture();
  assert.equal(await hasCurrentOwnerAccess('test-token', 'foreign', f.fetcher), false);
  assert.equal(f.calls.length, 0);
});
for (const [name, response] of [['deleted user', {}], ['different Auth user', { id: 'foreign' }], ['expired session', new Response('{}', { status: 401 })]]) {
  test(name, async () => {
    const f = fixture([response]);
    assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), false);
    assert.equal(f.calls.length, 1);
  });
}
for (const [name, rows] of [
  ['revoked membership', []], ['inactive membership', [{ ...member, status: 'inactive' }]],
  ['downgraded role', [{ ...member, role: 'member' }]], ['foreign organization', [{ ...member, organization_id: 'foreign' }]],
  ['foreign member', [{ ...member, user_id: 'foreign' }]], ['duplicate membership', [member, member]], ['malformed membership', {}]
]) test(name, async () => {
  const f = fixture([{ id: OWNER }, rows]);
  assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), false);
  assert.equal(f.calls.length, 2);
});
for (const [name, rows] of [
  ['inactive organization', [{ id: ORGANIZATION, status: 'inactive' }]], ['missing organization', []],
  ['foreign organization response', [{ id: 'foreign', status: 'active' }]], ['malformed organization', null]
]) test(name, async () => {
  const f = fixture([{ id: OWNER }, [member], rows]);
  assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), false);
});
for (const stage of [0, 1, 2]) test(`network failure at stage ${stage} denies`, async () => {
  const responses = valid(); responses[stage] = new Error('network');
  const f = fixture(responses);
  assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), false);
});
test('membership is rechecked after prior successful call', async () => {
  const f = fixture([...valid(), { id: OWNER }, []]);
  assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), true);
  assert.equal(await hasCurrentOwnerAccess('test-token', OWNER, f.fetcher), false);
  assert.equal(f.calls.length, 5);
});
