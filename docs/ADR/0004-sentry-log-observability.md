# ADR 0004 - Sentry Logging Observability

- Status: Accepted
- Date: 2026-05-20

## Context
The relay runs as an always-on service and needs production-grade error visibility without introducing broad instrumentation or changing route/use-case code.

## Decision
Enable Sentry as an optional observability sink at process entrypoint level:
- Initialize Sentry only when the app is started in release mode and `SENTRY_DSN` is set.
- Add `SentryLogHandler` to the logging pipeline with threshold `.warning`.
- Keep console logging enabled in all environments.
- Gracefully flush and shutdown Sentry during app shutdown and on execution errors.

## Consequences
### Advantages
- Centralized integration in bootstrap with no coupling to Domain/Application layers.
- Captures warnings and errors from the existing SwiftLog pipeline.
- No mandatory Sentry dependency at runtime when DSN is absent.

### Drawbacks
- No tracing/performance instrumentation at this stage.
- Events below warning level are not exported to Sentry.
- Non-release runs do not send events to Sentry by design.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Always-on Sentry in all environments | Too noisy for local/dev workflows and test runs. |
| Per-route manual capture calls | Adds coupling and duplicated logic across layers. |
| Dedicated telemetry worker/queue | Unnecessary operational complexity for current scope. |
