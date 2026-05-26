---
title: "ADR 0005 - Layered Restructuring Based on AGENTS.md"
filename: "0005-layered-restructuring-agents.md"
description: "Decision to restructure source and test folders around explicit architecture layers."
creation_date: 2026-05-26
update_date: 2026-05-26
category: adr
status: Accepted
---

# 0005 - Layered Restructuring Based on AGENTS.md

- **Status:** Accepted
- **Date:** 2026-05-26

## Context

The project started from a standard Vapor scaffold where folder naming and boundaries were functional but did not fully match the layered architecture model defined in `AGENTS.md`. The team needed explicit, verifiable boundaries to keep dependency direction clear and maintainable over time.

## Decision

We decided to reorganize the source code under `src/Code/` into four architecture layers:

```text
src/Code/
├── Adapters/
│   └── Network/
│       └── Handlers/
├── Application/
│   ├── App/
│   │   └── Middleware/
│   ├── Services/
│   └── UseCases/
├── Core/
│   ├── Models/
│   ├── Errors/
│   └── Protocols/
└── Shared/
    └── Extensions/
```

The test tree mirrors production layers:

```text
src/Tests/
├── App/
├── Application/
├── Adapters/Handlers/
├── Shared/
└── Helpers/
```

We also simplified package discovery by using `path: "Code"` in the package target so Swift Package Manager automatically discovers source files under the layered structure.

## Consequences

### Advantages

- Layer boundaries are visible directly in the repository tree.
- Core remains framework-agnostic and easy to test.
- Package configuration is smaller and less fragile.
- Test layout aligns with production architecture.
- Migration work removed stale assumptions in a subset of tests.

### Drawbacks / Risks

- Existing scripts or bookmarks referencing old paths had to be updated.
- Team members needed to adapt to the new folder conventions.

## Alternatives Considered

| Alternative | Reason Rejected |
|-------------|-----------------|
| Keep the original scaffold and apply conventions informally | Folder structure would continue to drift from architecture rules and reduce enforceability. |
| Create one Swift package target per layer | Added complexity not justified by current codebase size and deployment model. |
