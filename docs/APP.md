---
title: "webhook-irc-relay - Application overview"
filename: "APP.md"
description: "Product overview, scope, behavior, and operating constraints for the webhook to IRC relay service."
creation_date: 2026-04-27
update_date: 2026-05-26
category: product
author: Bruno Giarrizzo
status: active
---

# webhook-irc-relay - Application overview

## Product

### What is webhook-irc-relay?

webhook-irc-relay is a server application that receives inbound HTTP webhooks from external systems, normalizes each payload into a common event shape, and relays a formatted message to IRC. It is intended for operators who already use IRC channels for operational awareness and want a lightweight bridge from automation tools.

### Primary goal

> Deliver reliable and readable real-time webhook notifications to the correct IRC channel with minimal operational overhead.

### Scope

- Included: webhook ingestion, source-specific payload normalization, source-to-channel routing, IRC message delivery, and structured observability.
- Out of scope: database persistence, third-party queue brokers, and third-party IRC client libraries.
- Constraint: routing and source support are configured at bootstrap and deployed with the service.

### User roles

- System operator
- Security operator
- Platform engineer

## Experience

### Core flow

1. An external system sends a `POST /webhooks/:source` request.
2. The service validates and parses the source payload.
3. The payload is normalized into a `WebhookEvent`.
4. The event is routed to the mapped IRC channel and sent as a `PRIVMSG`.

### Key screens or entry points

- HTTP endpoint: `POST /webhooks/:source`
- OpenAPI endpoint: `GET /openapi.json`
- Swagger UI endpoint: `GET /swagger`

### Rules and behavior

- Unknown webhook sources are rejected with `404 Not Found`.
- Invalid payloads are rejected with `400 Bad Request`.
- Request correlation is propagated via `X-Request-Id` from ingress to logs and response.

## Accounts

### Account model

- No user accounts
- No authentication layer in v1
- No identity provider integration

### Sign in and sign up

- Not applicable
- Not applicable
- Not applicable

### User data

- No user profile data is stored.
- Incoming webhook payloads are processed in-memory.
- No cross-device synchronization exists.

### Account lifecycle

- Not applicable
- Not applicable
- Not applicable
- Not applicable

## Monetization

### Business model

- Internal and self-hosted service

### Access rules

- No tiering model in v1
- No paid access gates
- No expiration or cancellation lifecycle

### Purchases

- Not applicable
- Not applicable
- Not applicable

### Billing notes

- Not applicable
- Not applicable
- Not applicable

## Data and privacy

| Topic | Details |
|---|---|
| Data collected | Webhook payload fields, request metadata, source identifier, and delivery outcomes |
| Data usage | Parse payloads, route notifications, diagnose delivery failures |
| Storage | In-memory processing with runtime logs; no application database |
| Sharing | Messages are forwarded only to configured IRC infrastructure and optional Sentry |
| Tracking | No end-user tracking |
| Permissions | Network access only |
| Purpose strings / disclosures | Not applicable for server-side runtime |

## Security

### Security model

- Server-backed service
- Source validation and payload decoding at the HTTP boundary
- Trust boundary at inbound HTTP and outbound IRC connections

### Sensitive data

- Secrets: IRC credentials and optional Sentry DSN are read from environment variables.
- Tokens: no OAuth or API tokens are currently required by the relay itself.
- Personal data: not required by product design, but webhook payload content depends on upstream systems.
- Encryption: deploy behind TLS termination for inbound HTTP and use secure network paths for IRC.

### Transport and storage

- HTTPS is recommended for external ingress.
- Runtime configuration must be injected through environment variables.
- No durable storage layer is used by the application.

### Threat considerations

- Input validation and source matching at route level
- Payload decode failure handling with explicit HTTP errors
- Service-level rate limiting should be enforced at ingress proxy when needed
- Message sanitization prevents control-character injection in IRC output

## Platform support

### Supported platforms

| Platform | Minimum version |
|---|---|
| macOS | 13 |
| Linux | Compatible with Vapor 4 runtime |
| Docker | Engine with support for the provided Dockerfile |

### Platform-specific behavior

- CLI specifics: service runs as a Swift executable target.
- Web/API specifics: provides HTTP webhook and documentation endpoints.
- No mobile, desktop GUI, or watch runtime behavior.

## Technical design

### Architecture

- Layered backend architecture: Adapters, Application, Core, Shared
- Thin HTTP boundary in Application/App routes and middleware
- Source-specific normalization in Adapters/Network/Handlers
- Core contains framework-agnostic protocols, errors, and models

### Core dependencies

- Vapor 4
- SwiftNIO 2
- swift-openapi-vapor

### API and backend

- Main endpoint: `POST /webhooks/:source`
- Optional docs endpoints: `/openapi.json` and `/swagger`
- API errors are mapped to explicit HTTP statuses (`400`, `404`, `503`)

### Persistence

- No database
- No local cache ownership beyond runtime buffers in transport
- No migration strategy required in current scope

## Operations

### Logging and analytics

- Structured logs are emitted for HTTP ingress, decoding, routing, and IRC transport lifecycle.
- Payload normalization context is logged without introducing a persistence backend.
- Warning and error logs can be exported to Sentry when enabled.

### Error handling

- Client errors are returned with explicit status codes for invalid source or payload.
- IRC delivery failures are surfaced as service errors.
- Reconnect and buffering behavior mitigate transient IRC transport disruptions.

### Testing

- Unit tests for handlers and application services
- Integration tests for route behavior and app wiring
- Transport and logging tests for reliability and observability behavior

## Constraints

- No third-party IRC client library
- No database and no Fluent models in current design
- Source-to-channel routing is static at bootstrap
- Operational behavior depends on correct environment configuration

## Open questions

- Should webhook source registration evolve to a dynamic configuration file?
- Should request authentication be required for all inbound webhook sources?
- Should delivery retries become source-aware instead of transport-only buffering?
