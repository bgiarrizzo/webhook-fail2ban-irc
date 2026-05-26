---
title: "webhook-irc-relay - Tech stack"
filename: "STACK.md"
description: "Languages, frameworks, testing stack, deployment profile, and operational constraints."
creation_date: 2026-04-27
update_date: 2026-05-26
category: engineering
author: Bruno Giarrizzo
status: active
---

# webhook-irc-relay - Tech stack

## Language and version

| | |
|---|---|
| **Language** | Swift 6 |
| **Concurrency** | async and await, actors |
| **Strict concurrency** | Enabled by Swift 6 defaults and package settings |

## Frameworks

| Framework | Usage |
|---|---|
| **Foundation** | Core data types, parsing, and utility APIs |
| **Vapor** | HTTP server runtime, routing, middleware, and application lifecycle |
| **SwiftNIO** | TCP client transport for IRC delivery |
| **swift-openapi-vapor** | OpenAPI document and Swagger endpoint integration |
| **swift-log** | Structured logging facade and metadata propagation |
| **xcode-actions/json-logger** | JSONSeq log backend for machine-readable runtime logs |
| **swift-sentry (SwiftSentry)** | Optional warning and error sink in production-like runtime |
| **Swift Testing / XCTest interop** | Unit and integration testing support |
| **VaporTesting** | App bootstrapping and endpoint tests without external runtime dependencies |

Third-party dependencies are managed with Swift Package Manager.

## UI approach

- No UI layer.
- API-first backend service.
- No navigation model.
- No runtime animation model.
- No client-side localization framework in scope.
- Accessibility is not applicable for backend-only runtime.

## State management

```text
Inbound HTTP request
	-> Request middleware and metadata context
	-> ProcessWebhookUseCase
		-> WebhookDispatcher + HandlerRegistry
		-> IRCChannelRouter
		-> IRCClient actor
```

State ownership is explicit in services and the IRC transport actor. Dependency injection is performed during bootstrap wiring in application configuration.

## Testing

| Framework | Usage |
|---|---|
| **Swift Testing** | Unit tests for handlers, application services, and shared logic |
| **VaporTesting** | Integration tests for route wiring and request pipeline behavior |

Tests are split by layer:

- `src/Tests/App/` - API entrypoint and route behavior.
- `src/Tests/Application/` - service and routing orchestration.
- `src/Tests/Adapters/` - source handlers and transport-adjacent behavior.
- `src/Tests/Shared/` - cross-cutting logging and helper behavior.
- `src/Tests/Helpers/` - mocks and reusable test doubles.

## Target and deployment

| | |
|---|---|
| **Target** | Server executable |
| **Minimum version** | Swift 6 compatible host runtime |
| **Device** | Not applicable |
| **Orientation** | Not applicable |
| **Permissions** | Network access |
| **Entitlements** | Not applicable |
| **Network** | Required (HTTP ingress and IRC egress) |
| **Persistence** | No database, runtime memory only |

## Architecture notes

- Layered architecture with Adapters, Application, Core, and Shared boundaries.
- Core remains framework-agnostic and contract-oriented.
- Adapters own source-specific parsing and transport side effects.
- Application layer composes dependencies and orchestrates use cases.
- ADRs in `docs/ADR/` capture major architecture decisions.

## Dependencies and services

- Monitoring: optional Sentry event export for warnings and errors.
- Analytics: none.
- Payments: none.
- Authentication provider: none in v1.
- Backend database: none.
- External service: IRC server endpoint configured via environment variables.

## Build and release

- Build tool: Swift Package Manager.
- Executable target: `webhooks2irc`.
- Release profile: `swift build -c release`.
- Container artifact: multi-stage Docker image from `docker/Dockerfile`.
- Runtime binary is stripped in release container stage to reduce image size.

## Constraints

- No third-party IRC SDK is used by design.
- No database persistence in current product scope.
- Source-to-channel routing is bootstrap-defined, not runtime-editable.
- Sentry export is intentionally disabled outside release mode by default.
