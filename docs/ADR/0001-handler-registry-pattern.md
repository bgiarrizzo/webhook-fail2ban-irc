# ADR 0001 - Handler Registry Pattern

- Status: Accepted
- Date: 2026-05-15

## Context
The service must support many webhook providers and allow adding new ones without modifying existing processing logic.

## Decision
Use a central HandlerRegistry keyed by sourceIdentifier. Each source implements WebhookHandlerProtocol and is registered only during app bootstrap.

## Consequences
### Advantages
- Open extension point for new sources.
- No switch-case sprawl in routing logic.
- Keeps route handler thin and stable.

### Drawbacks
- Mis-registration is a runtime issue if bootstrap is incorrect.
