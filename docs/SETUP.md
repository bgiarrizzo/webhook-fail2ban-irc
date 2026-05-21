# SETUP

## Prerequisites
- Swift 6.0+
- macOS 13+ (or Linux compatible with Vapor 4)

## Environment variables

### Sentry (optional)

- SENTRY_DSN: DSN used to initialize Sentry.

Sentry activation rules:
- Sentry is initialized only when the process runs in release mode.
- If `SENTRY_DSN` is missing or empty, the app continues without Sentry.
- Sentry receives log events at warning level or higher.
- Console logging remains enabled even when Sentry is active.
- Sentry events are enriched indirectly through structured log metadata such as request_id, source, event_type, payload_bytes, IRC channel, and transport errors.

Example:
- `export SENTRY_DSN='https://<public_key>@o0.ingest.sentry.io/<project_id>'`

Operational note:
- On shutdown (normal or error path), the app flushes and shuts down Sentry gracefully.

### IRC
- IRC_HOST
- IRC_PORT
- IRC_NICK
- IRC_PASSWORD (optional)

### IRC channels (optional overrides)
- IRC_CHANNEL_SEEDBOX (default: #seedbox)
- IRC_CHANNEL_GIT (default: #git)
- IRC_CHANNEL_SYSOPS (default: #sysops)

### API documentation toggle
- SWAGGER_ENABLED (optional)

Default behavior:
- production: Swagger and OpenAPI endpoints disabled by default
- non-production: Swagger and OpenAPI endpoints enabled by default

## Run locally
1. swift build
2. swift run

## API documentation
- OpenAPI spec: GET /openapi.json
- Swagger UI: GET /swagger

## Debugging notes
- Send an `X-Request-Id` header from upstream systems when possible to correlate their traces with API and Sentry logs.
- If no `X-Request-Id` is provided, the middleware generates one and echoes it back in the response.
- Increase the process log level to inspect route execution, webhook normalization, and IRC transport state transitions.

## Run tests
1. swift test

Integration tests use `VaporTesting` helpers that configure the app through an explicit async closure, so fixtures can inject IRC and configuration overrides without starting a real IRC connection.
The basic app test also uses a mocked IRC client and asserts the real root route response returned by `src/App/routes.swift`.

## Build and run with Docker
1. Build image
  - `docker build -f docker/Dockerfile -t webhooks-irc:latest .`
2. Run container
  - `docker run --rm -p 8080:8080 -e IRC_HOST=irc.example.net -e IRC_PORT=6667 -e IRC_NICK=webhooks-bot webhooks-irc:latest`

Build notes:
- The Dockerfile uses BuildKit cache mounts for apt and SwiftPM caches.
- Only `Package.*` and `src/` are copied to compile layers, so docs/test-only edits do not invalidate dependency/build cache.
- The release binary is stripped during image build to reduce runtime image size.

## Example request
curl -X POST http://127.0.0.1:8080/webhooks/fail2ban \
  -H 'Content-Type: application/json' \
  -d '{"type":"ban","ip":"203.0.113.10","jail":"sshd"}'
