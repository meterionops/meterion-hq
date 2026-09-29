import http from "node:http";

const port = Number(process.env.PORT || 10000);
const upstream = "https://cavvdvxicadgfftbziao.supabase.co/functions/v1/control-room-web-v1";
const ownerProjectsUrl = "https://ai-company-os-ceo-dashboard.vercel.app/projects.html";
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

function redirectOwnerUi(res) {
  setSecurityHeaders(res);
  res.statusCode = 302;
  res.setHeader("Location", ownerProjectsUrl);
  res.end();
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
      return redirectOwnerUi(res);
    }
    if (req.method === "GET" || req.method === "HEAD") {
      return redirectOwnerUi(res);
    }
    if (req.method === "POST") {
      return await proxyPost(req, res);
    }
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
