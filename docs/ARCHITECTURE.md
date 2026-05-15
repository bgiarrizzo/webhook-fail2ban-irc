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
2. WebhookAuthMiddleware validates source token.
3. ProcessWebhookUseCase delegates to WebhookDispatcher.
4. HandlerRegistry resolves a source handler.
5. Handler decodes payload into WebhookEvent.
6. IRCChannelRouter resolves target channel.
7. IRCClient sends PRIVMSG to IRC.

## API documentation endpoints
- GET /openapi.json serves the OpenAPI document used by clients and tooling.
- GET /swagger serves Swagger UI backed by /openapi.json.
- Both routes are disabled in production by default and enabled outside production by default.

## Error mapping
- unknownSource -> HTTP 404
- invalidPayload -> HTTP 400
- invalid token -> HTTP 401
- IRC transport unavailable -> HTTP 503

## Runtime resilience
- IRCClient keeps a persistent TCP connection.
- On disconnect, it reconnects automatically.
- When disconnected, outbound messages are buffered in a memory queue and flushed after reconnect.
