---
title: "ADR 0004 - Sentry Logging Observability"
filename: "0004-sentry-log-observability.md"
description: "Decision to integrate Sentry as an optional warning and error sink at bootstrap level."
creation_date: 2026-05-20
update_date: 2026-05-26
category: adr
status: Accepted
---

# 0004 - Sentry Logging Observability

- **Status:** Accepted
- **Date:** 2026-05-20

## Context

The relay runs continuously and needs production-focused error visibility without coupling business logic to telemetry SDK calls.

## Decision

We decided to enable Sentry as an optional observability sink at process entrypoint level:

- Initialize Sentry only in release mode and only when `SENTRY_DSN` is configured.
- Add `ContextualSentryLogHandler` to the logging pipeline with `warning` threshold.
- Keep local console and JSON logging active in all environments.
- Flush and shut down Sentry gracefully during process shutdown and execution failures.

## Consequences

### Advantages

- Centralized integration without leaking telemetry concerns into business layers.
- Reuses the existing structured logging pipeline for warning and error exports.
- Zero operational overhead when `SENTRY_DSN` is not configured.

### Drawbacks / Risks

- No tracing or performance instrumentation in current scope.
- Events below warning level are not exported.
- Local debug runs do not send Sentry events by design.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Always-on Sentry in all environments | Produces too much noise for local development and test pipelines. |
| Manual per-route capture calls | Increases coupling and duplicates telemetry logic across layers. |
| Separate telemetry worker or queue | Adds operational complexity disproportionate to current product scope. |
