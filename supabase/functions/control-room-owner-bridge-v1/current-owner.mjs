// Public application key: never use a service role to resolve caller membership.
const BASE = 'https://yokcfxcbomuaupxxxoha.supabase.co';
const PUBLIC_KEY = 'sb_publishable_ip_oZDtDAa5hqy1kQ8TfGg_p3DCSnzj';
export const OWNER = '06ba24f1-556e-4e41-a735-79c94d20d3b0';
export const ORGANIZATION = '2e737407-7aa5-4567-a8bf-0d110cfef2ae';

// Called after signature/issuer/audience checks, on every request. No positive cache.
export async function hasCurrentOwnerAccess(token, userId, fetcher = fetch) {
  if (userId !== OWNER) return false;
  const signal = AbortSignal.timeout(5000);
  const headers = { apikey: PUBLIC_KEY, Authorization: `Bearer ${token}` };
  const read = async (path) => {
    const response = await fetcher(`${BASE}${path}`, { headers, signal, cache: 'no-store', redirect: 'error' });
    if (!response.ok) throw new Error('authorization_lookup_failed');
    return response.json();
  };
  try {
    const user = await read('/auth/v1/user');
    if (user?.id !== userId) return false;
    const members = await read(`/rest/v1/organization_members?select=organization_id,user_id,role,status&organization_id=eq.${ORGANIZATION}&user_id=eq.${OWNER}&limit=2`);
    if (!Array.isArray(members) || members.length !== 1) return false;
    const member = members[0];
    if (member?.organization_id !== ORGANIZATION || member?.user_id !== OWNER || member?.role !== 'owner' || member?.status !== 'active') return false;
    const organizations = await read(`/rest/v1/organizations?select=id,status&id=eq.${ORGANIZATION}&limit=2`);
    return Array.isArray(organizations) && organizations.length === 1 && organizations[0]?.id === ORGANIZATION && organizations[0]?.status === 'active';
  } catch {
    // Revoked/deleted sessions, unavailable upstream and malformed responses all deny.
    return false;
  }
}
