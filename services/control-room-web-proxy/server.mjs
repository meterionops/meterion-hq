import http from "node:http";

const port = Number(process.env.PORT || 10000);
const upstream = "https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-web-v1";
const maxBodyBytes = 64 * 1024;

function setSecurityHeaders(res) {
  res.setHeader("Cache-Control", "no-store");
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "no-referrer");
  res.setHeader("X-Frame-Options", "DENY");
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
}

function writeJson(res, status, body) {
  setSecurityHeaders(res);
  res.statusCode = status;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.end(JSON.stringify(body));
}

async function readBody(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > maxBodyBytes) throw new Error("request_too_large");
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

async function serveHtml(res) {
  const response = await fetch(`${upstream}?render_proxy=1`, {
    method: "GET",
    redirect: "manual",
    headers: { "user-agent": "meterion-control-room-web/1" },
  });
  const body = await response.text();
  if (!response.ok) {
    return writeJson(res, 502, { ok: false, code: "upstream_html_unavailable", upstream_status: response.status });
  }
  setSecurityHeaders(res);
  res.statusCode = 200;
  res.setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Content-Disposition", "inline");
  res.end(body);
}

async function proxyPost(req, res) {
  const body = await readBody(req);
  const headers = { "content-type": req.headers["content-type"] || "application/json" };
  if (req.headers.authorization) headers.authorization = req.headers.authorization;
  const response = await fetch(upstream, {
    method: "POST",
    headers,
    body,
    redirect: "manual",
  });
  const text = await response.text();
  setSecurityHeaders(res);
  res.statusCode = response.status;
  res.setHeader("Content-Type", response.headers.get("content-type") || "application/json; charset=utf-8");
  res.end(text);
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
    if (url.pathname === "/healthz") {
      return writeJson(res, 200, { ok: true, service: "meterion-control-room-web", upstream });
    }
    if (url.pathname !== "/") {
      res.statusCode = 302;
      res.setHeader("Location", "/");
      return res.end();
    }
    if (req.method === "GET" || req.method === "HEAD") return await serveHtml(res);
    if (req.method === "POST") return await proxyPost(req, res);
    res.setHeader("Allow", "GET, HEAD, POST");
    return writeJson(res, 405, { ok: false, code: "method_not_allowed" });
  } catch (error) {
    const code = error instanceof Error ? error.message : "proxy_error";
    return writeJson(res, code === "request_too_large" ? 413 : 502, { ok: false, code });
  }
});

server.listen(port, "0.0.0.0", () => {
  console.log(`meterion-control-room-web listening on ${port}`);
});
