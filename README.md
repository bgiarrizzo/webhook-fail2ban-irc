# webhook-irc-relay

Swift/Vapor webhook relay that normalizes incoming events and forwards them to IRC channels.

## What it does
- Receives POST webhooks at /webhooks/:source.
- Normalizes payloads into a common domain event shape.
- Routes each source to a specific IRC channel.
- Joins configured IRC channels and announces presence with a startup message.
- Sends formatted PRIVMSG lines over a persistent IRC TCP connection.
- Publishes API docs with OpenAPI at /openapi.json and Swagger UI at /swagger.
- Optionally forwards warning/error logs to Sentry in release mode when SENTRY_DSN is configured.
- Emits structured logs across HTTP ingress, routing, normalization, and IRC transport with request correlation metadata.

## Observability
- Every request receives or propagates an X-Request-Id header.
- Logs include request and troubleshooting context such as source, event type, payload size, user agent, remote address, IRC channel, and transport state.
- Structured logs are emitted as JSONSeq through JSONLogger.
- Warning and error logs can be forwarded to Sentry through SwiftSentry while JSON logging remains enabled.
- Warning and error events sent to Sentry are enriched with a short in-memory breadcrumb trail built from recent application logs, scoped by request_id when available.
- IRC connection lifecycle events are logged, including connect, handshake, JOIN, disconnect, reconnect, queueing, and message flush.

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

## Docker
- Build image:
```bash
docker build -f docker/Dockerfile -t webhooks-irc:latest .
```
- Run image:
```bash
docker run --rm -p 8080:8080 \
	-e IRC_HOST=irc.example.net \
	-e IRC_PORT=6667 \
	-e IRC_NICK=webhooks-bot \
	webhooks-irc:latest
```

The Docker build is optimized to reduce rebuild time by caching SwiftPM resolution/build artifacts and by copying only Swift sources needed for compilation.

## Documentation
- docs/APP.md
- docs/ARCHITECTURE.md
- docs/FEATURES.md
- docs/SETUP.md
- docs/STACK.md
- docs/ADR/
