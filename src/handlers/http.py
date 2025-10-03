import json
from http.server import BaseHTTPRequestHandler

from .fail2ban import fail2ban

from config import settings

CONTENT_TYPE = "content-type"
CONTENT_LEN = "content-length"


class HTTPHandler(BaseHTTPRequestHandler):
    irc = None

    def do_METHOD(self):
        method = self.command
        if method not in settings.HTTP_ALLOWED_METHODS:
            self.send_error(
                409, "Method Not Allowed", f"{method} requests are not allowed"
            )
            return

        if method == "POST":
            self.handle_post()

    def handle_post(self):
        if not self.validate_headers():
            return

        data = self.get_json_data()
        if data is None:
            return

        event_type = self.extract_event_info(data)

        self.send_response(200)
        self.send_header("content-type", "text/html")
        self.end_headers()
        self.wfile.write(b"OK")

        if self.irc:
            fail2ban.handle_event(
                irc=self.irc, event_type=event_type, data=data
            )
        else:
            print("Error: IRC connection not set")

    def validate_headers(self):
        if not all(x in self.headers for x in [CONTENT_TYPE, CONTENT_LEN]):
            self.send_error(400, "Bad Request", "Missing required headers")
            return False
        if self.headers[CONTENT_TYPE] != "application/json":
            self.send_error(400, "Bad Request", "Expected a JSON request")
            return False
        return True

    def get_json_data(self):
        content_length = int(self.headers[CONTENT_LEN])
        try:
            return json.loads(self.rfile.read(content_length))
        except json.JSONDecodeError:
            self.send_error(400, "Bad Request", "Invalid JSON")
            return None

    def get_event_type(self, data):
        if data.get("eventType"):
            return data["eventType"].lower()
        return data["type"].lower()

    def extract_event_info(self, data):
        event_type = self.get_event_type(data)
        return event_type

    @classmethod
    def set_irc(cls, irc_connection):
        cls.irc = irc_connection

    # Définir toutes les méthodes HTTP comme do_METHOD
    for method in [
        "GET",
        "POST",
        "PUT",
        "DELETE",
        "HEAD",
        "OPTIONS",
        "TRACE",
        "CONNECT",
        "PATCH",
    ]:
        exec(f"do_{method} = do_METHOD")
