---
title: "webhook-irc-relay - Architecture"
filename: "ARCHITECTURE.md"
description: "Architecture overview, layer boundaries, request flow, and dependency rules for the webhook relay service."
creation_date: 2026-04-27
update_date: 2026-05-26
category: architecture
author: Bruno Giarrizzo
status: active
---

# webhook-irc-relay - Architecture

## Overview

The service follows a layered backend architecture designed for clear separation of concerns and maintainable source onboarding. HTTP transport responsibilities stay in the application boundary, normalization logic stays in handlers, and domain contracts remain framework-agnostic in Core.

```text
App -> UseCases / Services -> Core
Adapters -> Core
Shared -> (cross-cutting only)
```

All layers in this diagram are present in the project. No persistence layer is used in the current version.

## Canonical folder layout

```text
src/Code/
├── Adapters/
│   └── Network/
│       ├── IRCClient.swift
│       ├── IRCInboundHandler.swift
│       └── Handlers/
│
├── Application/
│   ├── App/
│   │   ├── Middleware/
│   │   ├── configure.swift
│   │   └── routes.swift
│   ├── Services/
│   └── UseCases/
│
├── Core/
│   ├── Errors/
│   ├── Models/
│   └── Protocols/
│
└── Shared/
    ├── Extensions/
    └── ContextualSentryLogHandler.swift
```

## Layer rules

| Layer | Responsibility | Must not |
|---|---|---|
| **App** | Routing, middleware, request/response mapping, bootstrap | Implement source-specific payload parsing logic |
| **Services / UseCases** | Orchestration, workflow composition, dispatch decisions | Depend on concrete transport details |
| **Core** | Domain models, protocol contracts, domain errors | Import Vapor, SwiftNIO transport code, or framework-specific concerns |
| **Adapters** | Concrete network and handler implementations | Leak transport details into Core contracts |
| **Shared** | Generic reusable helpers and extensions | Encode business rules tied to one webhook source |

## Layer diagram

```text
┌─────────────────────────────────────────────┐
│                 App Layer                   │
│ routes.swift / middleware / configure.swift │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│      Application Services and Use Cases     │
│ ProcessWebhookUseCase / WebhookDispatcher   │
│ HandlerRegistry / IRCChannelRouter          │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│                    Core                     │
│ Models / Protocols / Errors                 │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│                 Adapters                    │
│ IRC transport + source webhook handlers     │
└─────────────────────────────────────────────┘
```

## Dependency injection

Dependencies are wired explicitly during bootstrap in `configure.swift` using initializer-style composition. The application builds concrete adapters, then injects them into services and use cases through protocol contracts.

```swift
// Production wiring (conceptual)
let registry = HandlerRegistry()
registry.register(Fail2banWebhookHandler())

let dispatcher = WebhookDispatcher(registry: registry)
let useCase = ProcessWebhookUseCase(dispatcher: dispatcher, channelRouter: router, ircClient: ircClient)
```

Protocols are defined in Core. Concrete implementations live in Adapters and are composed in Application/App.

## Testing strategy

| Type | Strategy |
|---|---|
| **Core** | Unit tests for event models, error mapping, and protocol-driven behavior |
| **Services / UseCases** | Unit tests for dispatch and routing workflows with test doubles |
| **Handlers** | Source-specific payload parsing and normalization tests |
| **App / Routes** | Integration tests for endpoint status, request flow, and middleware behavior |
| **Observability** | Tests for structured log metadata and Sentry handler behavior |

```text
src/Tests/
├── App/
├── Application/
├── Adapters/
├── Shared/
└── Helpers/
```

## Domain

### Entities

The domain layer is centered on normalized webhook events, IRC channel abstractions, and connection configuration models that remain independent from transport frameworks.

### Use cases

The main use case is `ProcessWebhookUseCase`, implemented with async workflows and delegated services for handler resolution, event routing, and outbound delivery.

### Rules

- Every supported source must have one registered handler.
- Every source must map to one target IRC channel.
- Every inbound payload must be normalized before transport delivery.

## Presentation

### View / screen structure

Not applicable. This project is API-first and has no UI presentation layer.

### View model responsibilities

Not applicable.

### Shared UI components

Not applicable.

## Data / infrastructure

This project has infrastructure concerns (network transport and webhook decoding) but no database or repository layer.

### Repositories

No repository abstractions are required in the current scope.

### Network / backend

Inbound API traffic is handled by Vapor routes and middleware. Outbound IRC traffic is handled by a SwiftNIO-based TCP client with reconnect and queue flush behavior.

### Persistence

No local or remote persistence is implemented in v1.

## Backend / API

### Request flow

1. `POST /webhooks/:source` is received by Vapor routing.
2. Middleware injects or propagates `X-Request-Id` and request metadata.
3. `ProcessWebhookUseCase` delegates source handling to `WebhookDispatcher`.
4. `HandlerRegistry` resolves the source adapter implementing `WebhookHandlerProtocol`.
5. The handler decodes payload into a normalized `WebhookEvent`.
6. `IRCChannelRouter` maps source to a target channel.
7. `IRCClient` sends an IRC `PRIVMSG` to the server.

### Modules

- Routing and middleware in `Application/App`
- Dispatch and routing orchestration in `Application/Services` and `Application/UseCases`
- Source and transport adapters in `Adapters/Network`
- Domain contracts and models in `Core`

### Response rules

- Error shape is explicit through HTTP status mapping.
- Validation failures return `400`.
- Unknown source returns `404`.
- IRC transport unavailability returns `503`.

## Platform notes

### Supported platforms

| Platform | Minimum version |
|---|---|
| macOS | 13 |
| Linux | Vapor 4 compatible runtime |
| Docker | Environment capable of running the provided container image |

### Platform-specific behavior

- API and runtime behavior are platform-neutral under Swift and Vapor.
- Documentation endpoints are enabled by default outside production.

## Dependency rules

- App may depend on Application, Core, Adapters, and Shared.
- Core must stay independent from Vapor and transport specifics.
- Adapters may depend on Core contracts.
- Shared should remain framework-agnostic or strictly cross-cutting.
- Protocols live in Core; concrete implementations live in Adapters.

## Architecture decisions

- Handler registry pattern for source extensibility.
- Direct IRC TCP transport over third-party IRC libraries.
- Centralized multi-channel routing in one service.
- Optional Sentry sink integrated at bootstrap.
- Layered restructuring aligned with AGENTS guidance.

See ADRs in `docs/ADR/` for details.

## Constraints

- No Fluent or database persistence in v1.
- No external broker for asynchronous job processing.
- No third-party IRC transport dependency.
- Source routing is static at bootstrap time.

## Open questions

- Should the service add source authentication middleware?
- Should channel routing become environment-driven instead of code-wired?
- Should failed outbound deliveries support retry policies beyond reconnect buffering?
