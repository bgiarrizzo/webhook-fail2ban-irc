---
title: "Documentation index"
filename: "README.md"
description: "Entry point for the project documentation and reading order."
creation_date: 2026-04-27
update_date: 2026-05-26
category: meta
author: Bruno Giarrizzo
---

# Documentation

## Start here
1. Read `AGENTS.md` for global engineering rules.
2. Read [docs/APP.md](APP.md) for product scope and behavior.
3. Read [docs/ARCHITECTURE.md](ARCHITECTURE.md) for layering and dependency direction.
4. Check [docs/ADR/](ADR/) for architectural decisions and constraints.

## Reading guide

### Product and behavior
- [docs/APP.md](APP.md) — source of truth for user-facing behavior.
- [docs/FEATURES.md](FEATURES.md) — feature catalog and supported webhook sources.

### Architecture and runtime
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) — layer boundaries, request flow, and observability.
- [docs/STACK.md](STACK.md) — runtime stack, transports, and test tooling.

### Setup and operations
- [docs/SETUP.md](SETUP.md) — local setup, environment variables, run/test commands, Docker.

### Decisions
- [docs/ADR/0000-adr-index.md](ADR/0000-adr-index.md) — ADR index.
- [docs/ADR/ADR_TEMPLATE.md](ADR/ADR_TEMPLATE.md) — ADR template.

## Sources of truth
- Product behavior and feature rules: [docs/APP.md](APP.md)
- Architecture and code organization: [docs/ARCHITECTURE.md](ARCHITECTURE.md)
- Historical decisions: [docs/ADR/](ADR/)
- Global engineering practices: `AGENTS.md`
