---
title: "webhook-irc-relay - Features"
filename: "FEATURES.md"
description: "Complete feature inventory for webhook ingestion, routing, delivery, and observability."
creation_date: 2026-04-27
update_date: 2026-05-26
category: product
author: Bruno Giarrizzo
status: active
---

# webhook-irc-relay - Features

## Overview

This document describes the current product feature set for webhook intake, normalization, channel routing, and IRC delivery. Features are grouped by capability and tracked with stable IDs.

## Feature index

| # | Feature | Status |
|---|---|---|
| F-01 | Webhook endpoint ingestion | `done` |
| F-02 | Source-specific payload normalization | `done` |
| F-03 | Centralized source-to-channel routing | `done` |
| F-04 | IRC connection lifecycle and delivery | `done` |
| F-05 | Message sanitization and formatting safety | `done` |
| F-06 | Request correlation and structured logging | `done` |
| F-07 | Optional Sentry warning and error export | `done` |
| F-08 | API documentation endpoints | `done` |

---

## F-01 - Webhook endpoint ingestion

**Status:** `done`
**Area:** API

### Description

The service exposes a webhook endpoint that receives source-specific payloads via HTTP and starts the normalization and relay workflow.

### User stories

- As a platform engineer, I can send webhook payloads to one endpoint pattern so that multiple sources can be integrated consistently.
- As an operator, I can detect unsupported sources immediately through explicit HTTP responses.

### Behaviour rules

- The endpoint pattern is `POST /webhooks/:source`.
- Unknown source identifiers return `404 Not Found`.
- Invalid payload structures return `400 Bad Request`.

### Acceptance criteria

- [x] Requests with known sources are forwarded to the processing workflow.
- [x] Unknown sources are rejected with `404`.
- [x] Invalid payloads are rejected with `400`.

### Out of scope

- Authentication and authorization middleware for webhook origins.
- Versioned endpoint families.

### Notes

The endpoint currently assumes trusted network boundaries.

---

## F-02 - Source-specific payload normalization

**Status:** `done`
**Area:** Adapters

### Description

Each supported source has a dedicated handler that parses payload fields and maps them into a normalized event model for downstream routing and transport.

### User stories

- As a maintainer, I can add a new source by adding one handler so that source logic stays isolated.
- As an operator, I can receive stable IRC messages even when source schemas differ.

### Behaviour rules

- Handlers implement a shared protocol contract.
- Decoding failures are logged with structured context.
- Unknown source event subtypes are handled gracefully.

### Acceptance criteria

- [x] Handlers exist for Bazarr, Radarr, Sonarr, Lidarr, Prowlarr, and Fail2ban.
- [x] Each handler returns a normalized event output.
- [x] Parsing failures produce explicit errors and logs.

### Out of scope

- Dynamic runtime loading of handlers.
- Schema negotiation with upstream providers.

### Notes

The handler registry pattern is documented in ADR 0001.

---

## F-03 - Centralized source-to-channel routing

**Status:** `done`
**Area:** Application services

### Description

Routing decisions are centralized so each source maps to one configured IRC channel independent of handler internals.

### User stories

- As an operator, I can route security events and media events to different channels.
- As a maintainer, I can update channel routing in one place.

### Behaviour rules

- Routing logic is defined in `IRCChannelRouter`.
- Handlers do not choose channels directly.
- Unsupported mappings are surfaced during configuration and tests.

### Acceptance criteria

- [x] Active mappings include seedbox and sysops channels.
- [x] Future mappings for git-focused sources are pre-wired.
- [x] Routing logic is tested independently.

### Out of scope

- Per-event dynamic channel routing rules.
- User-defined channel mapping API.

### Notes

Routing centralization is documented in ADR 0003.

---

## F-04 - IRC connection lifecycle and delivery

**Status:** `done`
**Area:** Transport

### Description

The service maintains a persistent IRC TCP connection, joins configured channels, and sends normalized messages while handling transient disconnects.

### User stories

- As an operator, I can rely on automatic reconnect after IRC interruptions.
- As an operator, I can verify bot availability from channel join behavior.

### Behaviour rules

- Startup performs IRC handshake and channel joins.
- Outbound messages can be buffered while disconnected.
- Buffered messages are flushed after successful reconnect.

### Acceptance criteria

- [x] Bot joins configured channels at startup.
- [x] Connection loss triggers reconnect behavior.
- [x] Messages can be delivered after reconnection.

### Out of scope

- Multi-network IRC federation.
- Advanced delivery receipts from IRC server plugins.

### Notes

Direct transport design is documented in ADR 0002.

---

## F-05 - Message sanitization and formatting safety

**Status:** `done`
**Area:** Shared

### Description

Outbound messages are sanitized to reduce protocol control-character issues and formatting hazards before IRC delivery.

### User stories

- As an operator, I receive readable IRC messages even with noisy source payloads.

### Behaviour rules

- Control characters and unsafe line breaks are removed.
- Outbound message length is capped to transport-safe size.
- Source formatters produce concise summaries by event type.

### Acceptance criteria

- [x] Sanitization runs before transport write.
- [x] Message length cap is enforced.
- [x] Source summary formats are covered by tests.

### Out of scope

- Rich markdown rendering in IRC clients.

### Notes

Fail2ban summaries include contextual ban metadata and IP link references.

---

## F-06 - Request correlation and structured logging

**Status:** `done`
**Area:** Observability

### Description

The service emits structured logs with correlation metadata from ingress through dispatch and transport.

### User stories

- As an operator, I can trace one webhook request end-to-end using request ID.
- As a maintainer, I can diagnose parse and transport issues using structured metadata.

### Behaviour rules

- `X-Request-Id` is propagated or generated at ingress.
- Logs include method, path, source, payload size, event type, and target channel where available.
- Transport lifecycle events are captured for debugging.

### Acceptance criteria

- [x] Request correlation metadata is present in logs.
- [x] Response includes request ID header.
- [x] Handler and transport failure events are logged.

### Out of scope

- Full distributed tracing across external systems.

### Notes

Structured log forwarding to Sentry is covered by F-07.

---

## F-07 - Optional Sentry warning and error export

**Status:** `done`
**Area:** Observability

### Description

When enabled in release mode with environment configuration, warning and error logs are exported to Sentry without disabling local logs.

### User stories

- As an operator, I can monitor warning and error events from production deployments.

### Behaviour rules

- Sentry is initialized only in release builds when `SENTRY_DSN` is set.
- Warning and error thresholds are applied through a contextual log handler.
- Shutdown flushes pending events.

### Acceptance criteria

- [x] Sentry setup is optional and environment-driven.
- [x] Warning and error events can be exported.
- [x] Console logging remains active.

### Out of scope

- Performance tracing instrumentation.
- Event export in non-release runtime by default.

### Notes

Sentry decision details are documented in ADR 0004.

---

## F-08 - API documentation endpoints

**Status:** `done`
**Area:** API

### Description

The service exposes OpenAPI and Swagger endpoints for local development and operational validation.

### User stories

- As an engineer, I can inspect and validate webhook contracts quickly.

### Behaviour rules

- `GET /openapi.json` serves API schema.
- `GET /swagger` serves interactive UI.
- Endpoints are disabled by default in production and enabled by default outside production.

### Acceptance criteria

- [x] OpenAPI endpoint responds with schema.
- [x] Swagger endpoint loads documentation UI.
- [x] Environment mode toggles default visibility.

### Out of scope

- Publicly hosted long-term API portal.

### Notes

Visibility can be overridden with `SWAGGER_ENABLED`.

---

## Cross-cutting concerns

- **Error states:** Invalid source or payload returns explicit HTTP status and logged context.
- **Empty states:** Not applicable to UI, but unsupported or empty events are handled through explicit errors.
- **Loading states:** Not applicable to server API.
- **Offline behavior:** IRC disconnect handling includes reconnect and queue flush behavior.
- **Accessibility:** Not applicable to backend-only product.
- **Localization:** Message content is currently English-first and source-driven.

## Dependencies between features

| Feature | Depends on | Notes |
|---|---|---|
| F-02 | F-01 | Payload normalization requires webhook ingestion.
| F-03 | F-02 | Routing applies to normalized events.
| F-04 | F-03 | Delivery requires resolved channel routes.
| F-06 | F-01 | Correlation starts at ingress.
| F-07 | F-06 | Sentry export depends on structured log pipeline.
| F-08 | F-01 | API docs belong to the same HTTP surface.

## Out of scope (product level)

- Database-backed event history.
- External message broker processing pipeline.
- Third-party IRC SDK adoption.

## Open questions

- Should inbound webhook signing validation become mandatory for all providers?
- Should source/channel mappings move to external config for runtime updates?
