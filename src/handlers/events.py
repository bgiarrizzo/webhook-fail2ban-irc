from irc.connection import IrcConnection


class EventsHandler:
    def __init__(self):
        self.handlers = {
            # Bazarr Events
            "test": self._default_handler,
            "info": self._default_handler,
            "success": self._default_handler,
            "error": self._default_handler,
            "warning": self._default_handler,
            # Radarr Events
            "grab": self._default_handler,
            "import": self._default_handler,
            "upgrade": self._default_handler,
            "rename": self._default_handler,
            "added": self._default_handler,
            "file_deleted": self._default_handler,
            "file_deleted_for_upgrade": self._default_handler,
            "health_issue": self._default_handler,
            "health_restored": self._default_handler,
            "application_update": self._default_handler,
            "manual_interaction_required": self._default_handler,
        }

    def _default_handler(self, irc: IrcConnection, message: str):
        irc.send_message(message=message)

    def handle_event(self, event_type: str, irc: IrcConnection, message: str):
        handler = self.handlers.get(event_type, self._default_handler)
        handler(irc, message)


events_handler = EventsHandler()
