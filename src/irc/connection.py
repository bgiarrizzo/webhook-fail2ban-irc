import select
import time
import sys
import socket
import threading


PING_INTERVAL = 30
PING_TIMEOUT = PING_INTERVAL + 30  # Must be PING_INTERVAL + actual ping timeout
RETRY_INTERVAL = 60


ansi_colors = {
    "green": "1;32m",
    "blue": "1;34m",
    "red": "1;31m",
    "brown": "0;33m",
}


def colorize(line: str, color: str):
    if not sys.stdout.isatty():
        return line
    return "\033[" + ansi_colors[color] + line + "\033[0m"


class IrcConnection:
    def __init__(self, server, channel, nick, passw, port):
        self.server = server
        self.port = port
        self.nick = nick
        self.passw = passw
        self.channel = channel

        self.connection = None
        self.buffer = ""
        self.last_pong = 0
        self.await_pong = False
        self.queue = []
        self.lock = threading.Lock()
        self.quit_loop = False

    def connect_server(self):
        print(colorize(f"Connecting to {self.server}:{self.port}", "brown"))

        while not self.connection:
            try:
                self.connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.connection.connect((self.server, self.port))
                self.connection.setblocking(False)  # Important pour select non bloquant
            except socket.gaierror:
                print(
                    colorize(
                        "Couldn't resolve server, check your internet connection. Re-attempting in 60 seconds.",
                        "red",
                    )
                )
                self.connection = None
                time.sleep(RETRY_INTERVAL)

        self.last_pong = time.time()
        self.await_pong = False

        if self.passw:
            self.post_string(f"PASS {self.passw}\r\n")

        self.post_string(f"NICK {self.nick}\r\n")
        self.post_string(f"USER {self.nick} 0 * :{self.nick}\r\n")

        # Attente du message 001 (RPL_WELCOME)
        buffer = ""
        while True:
            try:
                data = self.connection.recv(4096)
                if not data:
                    continue
                buffer += data.decode("utf-8", errors="ignore")
                lines = buffer.split("\r\n")
                for line in lines[:-1]:
                    line = line.strip()
                    if not line:
                        continue
                    print(colorize(line, "green"))
                    if " 001 " in line:
                        # Connexion complète, on peut rejoindre le canal
                        self.post_string(f"JOIN {self.channel}\r\n")
                        return
                    # Réponse automatique aux PING pendant l'attente
                    if line.startswith("PING"):
                        pong_response = line.replace("PING", "PONG", 1)
                        self.post_string(pong_response + "\r\n")
                buffer = lines[-1]
            except BlockingIOError:
                # Pas de données encore
                time.sleep(0.1)

    def reconnect(self):
        if self.connection:
            try:
                self.connection.shutdown(socket.SHUT_RDWR)
                self.connection.close()
            except Exception:
                pass
        self.connection = None
        self.connect_server()

    def try_ping(self):
        self.post_string(f"PING {self.server}\r\n")
        self.await_pong = True

    def schedule_message(self, message: str):
        with self.lock:
            self.queue.append(message)

    def process_line(self, line: str):
        line = line.strip()
        if line.startswith("PING"):
            pong_response = line.replace("PING", "PONG", 1)
            self.post_string(pong_response + "\r\n")
        elif "PONG" in line:
            self.last_pong = time.time()
            self.await_pong = False
        else:
            print(f"{colorize(self.server, 'green')}: {line}")

    def process_input(self):
        assert self.connection is not None
        try:
            data = self.connection.recv(4096)
            if not data:
                # Serveur a probablement fermé la connexion, reconnecter
                self.reconnect()
                return
            self.buffer += data.decode("utf-8", errors="ignore")
            while "\r\n" in self.buffer:
                line, self.buffer = self.buffer.split("\r\n", 1)
                if line:
                    self.process_line(line)
        except BlockingIOError:
            # Pas de données disponibles actuellement
            pass
        except Exception:
            self.reconnect()

    def post_string(self, message: str):
        assert self.connection is not None
        try:
            print(colorize(self.nick + "> " + message.strip(), "blue"))
            self.connection.send(message.encode("utf-8"))
        except Exception:
            self.reconnect()

    def send_message(self, message: str):
        self.post_string(f"PRIVMSG {self.channel} :{message}\r\n")

    def stop_loop(self):
        self.quit_loop = True

    def loop(self):
        self.connect_server()

        self.send_message(f"{self.nick} is now online !")

        while not self.quit_loop:
            try:
                to_read, _, _ = select.select([self.connection], [], [], 1)
            except (select.error, ValueError):
                self.reconnect()
                continue

            now = time.time()
            if now - self.last_pong > PING_INTERVAL and not self.await_pong:
                self.try_ping()

            if now - self.last_pong > PING_TIMEOUT and self.await_pong:
                self.reconnect()
                continue

            if to_read:
                self.process_input()

            with self.lock:
                while self.queue:
                    self.send_message(self.queue.pop(0))

    def __del__(self):
        if self.connection:
            try:
                self.connection.shutdown(socket.SHUT_RDWR)
                self.connection.close()
            except Exception:
                pass
