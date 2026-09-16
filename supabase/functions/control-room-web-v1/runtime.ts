import app from "https://raw.githubusercontent.com/meterionops/meterion-hq/e6eb9ad3e33c08f17e55d117377f07d1d8f95df0/supabase/functions/control-room-web-v1/index.ts";

async function normalizeHtml(response: Response): Promise<Response> {
  const body = await response.text();
  const headers = new Headers(response.headers);
  headers.set("Content-Type", "text/html; charset=utf-8");
  headers.set("Content-Disposition", "inline");
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("Cache-Control", "no-store");
  headers.delete("Content-Length");
  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

Deno.serve(async (request: Request) => {
  const response = await app.fetch(request);
  if (request.method === "GET") return await normalizeHtml(response);
  return response;
});
