---
title: "ADR 0003 - Centralized Multi-Channel Routing"
filename: "0003-multi-channel-routing.md"
description: "Decision to centralize webhook source to IRC channel mapping in one service."
creation_date: 2026-05-15
update_date: 2026-05-26
category: adr
status: Accepted
---

# 0003 - Centralized Multi-Channel Routing

- **Status:** Accepted
- **Date:** 2026-05-15

## Context

Webhook handlers should focus on payload normalization and must not encode transport channel policy. Channel routing should remain consistent, testable, and easy to update.

## Decision

We decided to use `IRCChannelRouter` in `Application/Services` as the single source of truth for source-to-channel mapping. Handlers return normalized events only and never select channels directly.

## Consequences

### Advantages

- Clear separation of concerns between normalization and routing policy.
- Centralized updates when channel assignments change.
- Predictable routing behavior across all sources.

### Drawbacks / Risks

- Every new source requires explicit router mapping updates.
- Misconfigured routing can surface only at runtime without adequate tests.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Decide target channel inside each handler | Spreads policy across adapters and increases maintenance risk. |
