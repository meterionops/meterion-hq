import app from "https://raw.githubusercontent.com/meterionops/meterion-hq/e6eb9ad3e33c08f17e55d117377f07d1d8f95df0/supabase/functions/control-room-web-v1/index.ts";

const FRONTEND_URL = "https://meterion-control-room-web.onrender.com/";
const SUPABASE_REDIRECT_URL = "https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-web-v1";

function redirectTarget(request: Request): string {
  const incoming = new URL(request.url);
  const target = new URL(FRONTEND_URL);
  target.search = incoming.search;
  return target.toString();
}

async function rewriteMagicLinkRequest(request: Request): Promise<Request> {
  const text = await request.clone().text();
  let parsed: unknown;
  try {
    parsed = JSON.parse(text || "{}");
  } catch {
    return request;
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return request;
  const body = parsed as Record<string, unknown>;
  if (body.action !== "send_magic_link") return request;
  body.redirect_to = SUPABASE_REDIRECT_URL;
  const headers = new Headers(request.headers);
  headers.delete("content-length");
  headers.set("content-type", "application/json");
  return new Request(request.url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

export default {
  async fetch(request: Request): Promise<Response> {
    if (request.method === "GET" || request.method === "HEAD") {
      const url = new URL(request.url);
      if (url.searchParams.get("render_proxy") === "1") return await app.fetch(request);
      return new Response(null, {
        status: 302,
        headers: {
          location: redirectTarget(request),
          "cache-control": "no-store",
          "referrer-policy": "no-referrer",
          "x-content-type-options": "nosniff",
        },
      });
    }
    if (request.method === "POST") return await app.fetch(await rewriteMagicLinkRequest(request));
    return await app.fetch(request);
  },
};
