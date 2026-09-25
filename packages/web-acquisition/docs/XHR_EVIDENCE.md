# Replayable XHR evidence

`ScraplingEngine` can now retain response bodies alongside existing summaries.
Opt in explicitly, after the caller has approved a public endpoint pattern:

```python
from pathlib import Path
from meterion_web_acquisition import EngineRequest, retain_response
from meterion_web_acquisition.engines.scrapling_engine import ScraplingEngine

response = ScraplingEngine().collect(EngineRequest(
    url=source_url, mode="dynamic_browser",
    capture_xhr_pattern=approved_endpoint_pattern, retain_xhr_bodies=True,
))
manifest = retain_response(response, Path(evidence_directory),
                           source_identity_url=source_url)
```

Persist the returned manifest **and all referenced blobs** in the project's durable
evidence store before using an XHR-derived observation. The local sink alone is not
a durable deployment. `run_acquisition` does not enable XHR capture or this sink
implicitly; adoption remains explicit. No project parser/canonical logic was added.

The manifest separates identity URL, requested transport URL, final URL, fetch time,
raw page, extraction DOM, and each captured XHR's URL/status/type/hash/byte count.
Snapshot paths derive only from SHA256, never a source-controlled URL or filename.
Repeat content deduplicates; observation manifests retain distinct timestamps.
Readback checks detect corrupted preexisting blobs. Headers/cookies are not copied
into manifests. Bodies remain literal evidence; select permitted public endpoints
and do not enable broad capture against authenticated/personalized sessions.

Limits: 100 response records, 2 MiB per retained body, 10 MiB retained body total.
These bound retained copies, **not the browser/provider's earlier network buffering**.
Too-large, unavailable, disabled or count-limited evidence is explicit; no prefix
is misrepresented as a full body. Empty bytes have a valid hash and snapshot.
`xhr_evidence_complete` is false for omissions; true with zero responses only means
no captured response was omitted, not that useful XHR content was found.

Validation: `pytest -q` includes bytes roundtrip, omissions, identity and corruption
tests. `python scripts/xhr_replay_smoke_v1.py` uses a real Scrapling browser against
a loopback fixture (JSON, binary, empty body), verifies disk readback and rendered
DOM, and makes no external requests. It is also part of the existing CI workflow.
This fixture is not a genuine restaurant dynamic-source acceptance test.

API checked against Scrapling's official response/capture documentation:
https://scrapling.readthedocs.io/en/latest/fetching/dynamic.html
Provider remains pinned to Scrapling 0.4.15.
