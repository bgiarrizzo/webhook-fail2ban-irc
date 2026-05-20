# ARCHITECTURE

## Layering
- App: Vapor bootstrap, middleware, route transport wiring.
- Application: orchestration, source registry, channel routing, use case flow.
- Domain: framework-free core models and processing errors.
- Infrastructure: IRC TCP transport and source-specific handlers.
- Shared: JSON decoding and IRC text sanitization helpers.

## Dependency direction
- App -> Application -> Domain
- Infrastructure -> Domain

## Request flow
1. POST /webhooks/:source enters Vapor routing.
2. ProcessWebhookUseCase delegates to WebhookDispatcher.
3. HandlerRegistry resolves a source handler.
4. Handler decodes payload into WebhookEvent.
5. IRCChannelRouter resolves target channel.
6. IRCClient sends PRIVMSG to IRC.

## API documentation endpoints
- GET /openapi.json serves the OpenAPI document used by clients and tooling.
- GET /swagger serves Swagger UI backed by /openapi.json.
- Both routes are disabled in production by default and enabled outside production by default.

## Error mapping
- unknownSource -> HTTP 404
- invalidPayload -> HTTP 400
- IRC transport unavailable -> HTTP 503

## Observability (Sentry)
- Sentry integration is performed in `Application/App/entrypoint.swift`.
- Sentry is enabled only in release mode and only if `SENTRY_DSN` is defined.
- Logging is multiplexed: console handler is always active, Sentry handler is added conditionally.
- Sentry handler level is `warning` and above via `SentryLogHandler`.
- Shutdown path calls `sentry.shutdown()` to flush buffered events.

## Runtime resilience
- IRCClient keeps a persistent TCP connection.
- During initialization, it performs a handshake (NICK, USER, JOIN for each channel).
- After joining all channels, it announces presence with a message in each channel.
- On disconnect, it reconnects automatically.
- When disconnected, outbound messages are buffered in a memory queue and flushed after reconnect.
