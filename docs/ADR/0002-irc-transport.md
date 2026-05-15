# ADR 0002 - Direct IRC TCP Transport

- Status: Accepted
- Date: 2026-05-15

## Context
The project requires IRC relay capabilities while avoiding new third-party dependencies unless explicitly justified.

## Decision
Implement IRC transport directly with SwiftNIO over TCP, including handshake (PASS/NICK/USER), channel join, PRIVMSG sending, and reconnect behavior.

## Consequences
### Advantages
- No additional third-party library required.
- Full control over connection lifecycle and retries.
- Easier long-term maintenance under project constraints.

### Drawbacks
- More internal code to maintain for protocol handling.
