#!/usr/bin/env python3
# redirector.py

from http.server import HTTPServer, BaseHTTPRequestHandler

class RedirectHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Issue a 302 redirect to the internal URL
        self.send_response(302)
        self.send_header('Location', 'http://127.0.0.1/local.txt')
        self.end_headers()

    def log_message(self, format, *args):
        # Suppress default logging; uncomment next line if you want request logs
        # super().log_message(format, *args)
        pass

def run(host='0.0.0.0', port=8000):
    server = HTTPServer((host, port), RedirectHandler)
    print(f"[+] Listening on http://{host}:{port}/ — redirecting all GETs to 127.0.0.1/local.txt")
    server.serve_forever()

if __name__ == '__main__':
    run()