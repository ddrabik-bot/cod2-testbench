#!/usr/bin/env python3
"""
target-server — HTTP test server for execute_async_create curl tests.

Endpoints:
  GET  /api/hello       → {} (basic GET test)
  POST /api/echo        → echo JSON body back (POST test)
  GET  /api/delay/<N>   → {} after N seconds delay (timeout test)
  GET  /api/status/<N>  → returns HTTP status N (error test)
  GET  /api/headers     → returns request headers as JSON
  GET  /health          → {"status":"ok"} (health check)
"""

import http.server
import json
import time
import urllib.parse
import sys

class TestHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip('/')

        if path == '/api/hello':
            self._json_response({"status": "ok", "source": "target-server"})
        elif path == '/api/headers':
            self._json_response(dict(self.headers))
        elif path == '/api/health':
            self._json_response({"status": "ok"})
        elif path.startswith('/api/delay/'):
            try:
                delay = int(path.split('/')[-1])
                time.sleep(delay)
                self._json_response({"status": "ok", "delayed": delay})
            except (ValueError, IndexError):
                self._json_response({"error": "invalid delay"}, 400)
        elif path.startswith('/api/status/'):
            try:
                status_code = int(path.split('/')[-1])
                self._json_response({"status": status_code}, status_code)
            except (ValueError, IndexError):
                self._json_response({"error": "invalid status code"}, 400)
        else:
            self._json_response({"error": "not found"}, 404)

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip('/')

        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length) if content_length > 0 else b'{}'

        if path == '/api/echo':
            try:
                data = json.loads(body)
                data["_method"] = "POST"
                data["_headers"] = dict(self.headers)
                self._json_response(data)
            except json.JSONDecodeError:
                self._json_response({
                    "_method": "POST",
                    "_raw_body": body.decode('utf-8', errors='replace'),
                    "_headers": dict(self.headers)
                })
        else:
            self._json_response({"error": "not found"}, 404)

    def _json_response(self, data, status=200):
        body = json.dumps(data).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Server', 'target-server/1.0')
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        sys.stderr.write(f"[TARGET] {args[0]} {args[1]} {args[2]}\n")
        sys.stderr.flush()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = http.server.HTTPServer(('0.0.0.0', port), TestHandler)
    print(f"[TARGET] target-server listening on 0.0.0.0:{port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("[TARGET] shutdown", flush=True)
        server.server_close()