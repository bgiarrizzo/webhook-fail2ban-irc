# ADR 0003 - Centralized Multi-Channel Routing

- Status: Accepted
- Date: 2026-05-15

## Context
Webhook handlers should focus on payload normalization, not transport channel decisions. Channel routing must remain consistent and configurable.

## Decision
Use IRCChannelRouter in Application as the single source of truth for source-to-channel mapping. Handlers return normalized events only.

## Consequences
### Advantages
- Clear separation of concerns.
- Centralized route updates for channel changes.
- Predictable behavior across all handlers.

### Drawbacks
- New sources require router mapping updates at bootstrap time.
