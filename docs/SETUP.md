# SETUP

## Prerequisites
- Swift 6.0+
- macOS 13+ (or Linux compatible with Vapor 4)

## Environment variables
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
