import app from "https://raw.githubusercontent.com/meterionops/meterion-hq/e6eb9ad3e33c08f17e55d117377f07d1d8f95df0/supabase/functions/control-room-web-v1/index.ts";

function forceHtml(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Content-Type", "text/html; charset=utf-8");
  headers.set("Content-Disposition", "inline");
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("Cache-Control", "no-store");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

export default {
  async fetch(request: Request): Promise<Response> {
    const response = await app.fetch(request);
    if (request.method === "GET") return forceHtml(response);
    return response;
  },
};
