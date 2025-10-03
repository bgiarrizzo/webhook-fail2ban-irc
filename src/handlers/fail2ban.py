from datetime import datetime
from typing import Dict, Callable

from handlers.events import events_handler
from irc.connection import IrcConnection


class Fail2banEventHandler:
    def __init__(self):
        self.event_map = {
            "start": self.on_start,
            "stop": self.on_stop,
            "ban": self.on_ban,
            "unban": self.on_unban,
        }

    def send_message_to_event_handler(
        self, event_type: str, irc: IrcConnection, message: str
    ):
        message = f"{message}"
        events_handler.handle_event(event_type, irc, message)

    def handle_event(self, irc: IrcConnection, event_type: str, data: Dict):
        event_type = event_type.lower()
        handler = self.event_map.get(event_type, self.unknown_event)
        handler(irc, data)

    def unknown_event(self, irc: IrcConnection, data: Dict):
        message = (
            f"Unknown event type: {data.get('type', 'Unknown')} - Payload = {data}"
        )
        irc.send_message(message)

    def on_start(self, irc: IrcConnection, data: Dict):
        message = data.get("message", "Unknown")
        self.send_message_to_event_handler(irc=irc, event_type="start", message=message)

    def on_stop(self, irc: IrcConnection, data: Dict):
        message = data.get("message", "Unknown")
        self.send_message_to_event_handler(irc=irc, event_type="stop", message=message)

    def on_ban(self, irc: IrcConnection, data: Dict):
        message = data.get("message", "Unknown")
        self.send_message_to_event_handler(
            irc=irc, event_type="ban", message=message
        )

    def on_unban(self, irc: IrcConnection, data: Dict):
        message = data.get("message", "Unknown")
        self.send_message_to_event_handler(
            irc=irc, event_type="unban", message=message
        )


fail2ban = Fail2banEventHandler()
