---
title: "ADR 0001 - Handler Registry Pattern"
filename: "0001-handler-registry-pattern.md"
description: "Decision to use a central handler registry for webhook source resolution."
creation_date: 2026-05-15
update_date: 2026-05-26
category: adr
status: Accepted
---

# 0001 - Handler Registry Pattern

- **Status:** Accepted
- **Date:** 2026-05-15

## Context

The service must support multiple webhook providers and allow new providers to be added without changing the core dispatch workflow.

## Decision

We decided to use a central `HandlerRegistry` keyed by source identifier. Each source implements `WebhookHandlerProtocol` and is registered during application bootstrap.

## Consequences

### Advantages

- Open extension point for new webhook sources.
- Avoids switch-case growth in route and dispatch code.
- Keeps route handlers thin and stable over time.

### Drawbacks / Risks

- Mis-registration becomes a runtime configuration error.
- Bootstrap wiring must be covered by tests to prevent source drift.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Switch statement in route handler | Couples transport code with source-specific behavior and becomes hard to scale. |
| Static hard-coded mapping without registry abstraction | Reduces extensibility and makes source onboarding more error-prone. |
