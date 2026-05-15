# webhook-irc-relay

Swift/Vapor webhook relay that normalizes incoming events and forwards them to IRC channels.

## What it does
- Receives POST webhooks at /webhooks/:source.

- Normalizes payloads into a common domain event shape.
- Routes each source to a specific IRC channel.
- Sends formatted PRIVMSG lines over a persistent IRC TCP connection.
- Publishes API docs with OpenAPI at /openapi.json and Swagger UI at /swagger.

Swagger/OpenAPI exposure policy:
- Disabled by default in production.
- Enabled by default outside production.
- Can be overridden with SWAGGER_ENABLED.

## Supported sources
- bazarr
- radarr
- sonarr
- lidarr
- prowlarr
- fail2ban

## Quick start
1. Export environment variables described in docs/SETUP.md.
2. Build:
```bash
swift build
```
3. Run:
```bash
swift run
```
4. Test:
```bash
swift test
```

## Documentation
- docs/APP.md
- docs/ARCHITECTURE.md
- docs/FEATURES.md
- docs/SETUP.md
- docs/STACK.md
- docs/ADR/
