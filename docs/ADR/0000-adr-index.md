---
title: "ADR Index"
filename: "0000-adr-index.md"
description: "Index of all Architecture Decision Records (ADRs) for the project."
creation_date: 2026-04-27
update_date: 2026-05-26
category: adr
---

# ADR Index

This folder contains Architecture Decision Records (ADRs) for this app.

## ADR format
Each ADR MUST include:
- Status: Proposed | Accepted | Deprecated | Superseded
- Context
- Decision
- Consequences
- Alternatives considered (optional but recommended)

## Naming
- `NNNN-short-kebab-case-title.md`
- NNNN is a zero-padded incremental number starting at 0000.

## List

| # | File | Title | Status |
|---|------|-------|--------|
| 0000 | [0000-adr-index.md](0000-adr-index.md) | Index (this file) | — |
| TEMPLATE | [ADR_TEMPLATE.md](ADR_TEMPLATE.md) | ADR template | — |
| 0001 | [0001-handler-registry-pattern.md](0001-handler-registry-pattern.md) | Handler Registry Pattern | Accepted |
| 0002 | [0002-irc-transport.md](0002-irc-transport.md) | Direct IRC TCP Transport | Accepted |
| 0003 | [0003-multi-channel-routing.md](0003-multi-channel-routing.md) | Centralized Multi-Channel Routing | Accepted |
| 0004 | [0004-sentry-log-observability.md](0004-sentry-log-observability.md) | Sentry Logging Observability | Accepted |
| 0005 | [0005-layered-restructuring-agents.md](0005-layered-restructuring-agents.md) | Layered Restructuring Based on AGENTS.md | Accepted |
