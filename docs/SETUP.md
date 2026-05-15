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

## Example request
curl -X POST http://127.0.0.1:8080/webhooks/fail2ban \
  -H 'Content-Type: application/json' \
  -d '{"type":"ban","ip":"203.0.113.10","jail":"sshd"}'
