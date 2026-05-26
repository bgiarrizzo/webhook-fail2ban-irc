---
title: "ADR 0002 - Direct IRC TCP Transport"
filename: "0002-irc-transport.md"
description: "Decision to implement IRC transport directly with SwiftNIO over TCP."
creation_date: 2026-05-15
update_date: 2026-05-26
category: adr
status: Accepted
---

# 0002 - Direct IRC TCP Transport

- **Status:** Accepted
- **Date:** 2026-05-15

## Context

The relay requires IRC delivery while keeping dependency footprint low and avoiding unnecessary external libraries.

## Decision

We decided to implement IRC transport directly with SwiftNIO over TCP, including handshake commands (`PASS`, `NICK`, `USER`), channel joins, `PRIVMSG` delivery, reconnect handling, and message buffering behavior.

## Consequences

### Advantages

- No additional third-party IRC client dependency.
- Full control over connection lifecycle and operational behavior.
- Predictable adaptation for project-specific IRC requirements.

### Drawbacks / Risks

- Protocol handling logic must be maintained internally.
- Future IRC edge-case support may require additional implementation effort.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Third-party IRC client library | Adds dependency and reduces control over lifecycle, retries, and logging strategy. |
