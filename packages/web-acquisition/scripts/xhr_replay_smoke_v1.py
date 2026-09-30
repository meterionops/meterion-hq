"""Real Scrapling/browser loopback fixture; not a restaurant/source acceptance test."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import tempfile
from threading import Thread

from meterion_web_acquisition.engine import EngineRequest
from meterion_web_acquisition.engines.scrapling_engine import ScraplingEngine
from meterion_web_acquisition.snapshots import retain_response

PAYLOADS = {'/data': b'{"value":"fixture-target"}', '/binary': b'\x00\xff\x80', '/empty': b''}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = PAYLOADS.get(self.path)
        if body is None:
            body = b'''<html><body><div id="result">shell</div><script>
            Promise.all(['/data','/binary','/empty'].map(u=>fetch(u).then(r=>r.arrayBuffer())))
              .then(()=>document.querySelector('#result').textContent='fixture-target');
            </script></body></html>'''
        self.send_response(200)
        self.send_header('Content-Type', 'text/html' if self.path == '/' else 'application/octet-stream')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


def main():
    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    url = f'http://127.0.0.1:{server.server_port}/'
    try:
        response = ScraplingEngine().collect(EngineRequest(
            url=url, mode='dynamic_browser', wait_ms=1000,
            capture_xhr_pattern=r'/data$|/binary$|/empty$', retain_xhr_bodies=True))
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            manifest = retain_response(response, root, source_identity_url=url)
            assert manifest['xhr_evidence_complete'], manifest
            assert len(manifest['captured_responses']) == 3, manifest
            for entry in manifest['captured_responses']:
                path = '/' + entry['url'].rsplit('/', 1)[-1]
                assert (root / entry['raw_snapshot_ref']).read_bytes() == PAYLOADS[path]
            assert b'>fixture-target<' in response.content_for_extraction
            print('PASS: real browser XHR byte-for-byte replay (JSON, binary, empty); fixture only')
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == '__main__':
    main()
