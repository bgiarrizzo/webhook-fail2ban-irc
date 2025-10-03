from pydantic_settings import BaseSettings
from typing import List, Optional


class Settings(BaseSettings):
    # Attributes of the server this bot will run on
    HTTP_SERVER_HOST: Optional[str] = ""
    HTTP_SERVER_PORT: int = 8000
    HTTP_ALLOWED_METHODS: List[str] = ["POST"]

    # Attributes of the IRC connection
    IRC_SERVER: str = "127.0.0.1"
    IRC_PORT: int = 6667

    IRC_CHANNEL: str = "#fail2ban"
    IRC_NICK: str = "[BOT]_fail2ban"

    # Set the password for your registered empty, leave empty if not applicable
    # Note: freenode(and potentially other servers) want password to be of the form
    # "nick:pass", so for ex. IRC_PASS = 'WfTestBot:mypass123'
    IRC_PASS: Optional[str] = ""


settings = Settings()
