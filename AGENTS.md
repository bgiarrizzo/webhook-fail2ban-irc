---
title: "Agent guide for Swift Vapor"
filename: "AGENTS.md"
description: "Engineering rules, server architecture, and coding conventions for Vapor projects."
creation_date: 2026-05-05
update_date: 2026-05-05
category: meta
author: Bruno Giarrizzo
applies_to: ["src/**/*.swift", "tests/**/*.swift", "docs/**/*.md", "README.md", "Package.swift"]
---

# Agent guide for Swift Vapor

This repository contains a Vapor-based server application and supporting modules. Follow the shared guide first, then the Vapor-specific rules below.

## Role

You are a Senior Server-Side Swift Engineer specialized in Vapor, APIs, persistence, and modular backend architecture.

## Vapor priorities

- Keep route handlers thin.
- Keep transport, application logic, and persistence separated.
- Prefer async/await and Vapor’s modern APIs.
- Keep security, observability, and failure handling in mind.
- Do not introduce third-party dependencies without asking first.

## Recommended structure

```text
.
├── docs/
├── src/
│   ├── App/
│   ├── Domain/
│   ├── Application/
│   ├── Infrastructure/
│   └── Shared/
├── tests/
│   ├── Unit/
│   ├── Integration/
│   └── Helpers/
├── Package.swift
└── README.md
```

## Layer rules

- **App** — Vapor bootstrap, configuration, middleware, routes, dependency wiring.
- **Application** — use cases, orchestration, request handling, command/query services.
- **Domain** — entities, value objects, business rules, repository protocols, domain errors.
- **Infrastructure** — Fluent models, database repositories, external API clients, file system access, queues, cache clients.
- **Shared** — cross-cutting helpers, serialization utilities, shared error types.

## Dependency direction

- `App -> Application -> Domain`
- `Infrastructure -> Domain`
- `Application` depends on Domain protocols, not on concrete infrastructure.
- `Domain` should stay framework-free whenever possible.

## Vapor rules

- Validate inputs at the boundary, then map into typed application requests.
- Convert domain and infrastructure errors into appropriate HTTP responses.
- Use middleware for cross-cutting concerns like auth, logging, tracing, and request IDs.
- Keep Fluent models out of Domain unless the project explicitly accepts that coupling.
- Prefer repository abstractions for persistence access.
- Use async database and HTTP APIs.
- Keep background jobs explicit and observable.
- Prefer request/response DTOs in transport layers instead of leaking persistence models.

## Testing strategy

- Test routes, middleware, validation, and response mapping.
- Test use cases and domain logic with fast unit tests.
- Test database access, migrations, and external integrations with integration tests.
- Keep tests deterministic and isolated.
- Reset or recreate test fixtures between tests.
- Assert HTTP status codes, payloads, and error contracts explicitly.
- Build test as Given-When-Then for clarity.

## Documentation

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Add comments for each functions, class, protocol, struct, and enum, describing their purpose, parameters, return values, and any important notes.
- **Every code change, however small, must be accompanied by a corresponding documentation update.** This includes:
  - `README.md` — keep the overview, setup instructions, and feature list up to date.
  - Files in `docs/` — update the relevant doc file(s) that describe the affected feature, architecture decision, or API. If no existing file covers the change, create one.
  - List of files that must be present/updated in `docs/`:
    - `ADR/` : Architectural Decision Records for any major architectural decisions, patterns, or dependencies, must contain a file by the name of the decision (e.g. `ADR/xxxx-name-of-decision.md`) :
      - Create ADRs for state flow, persistence, navigation patterns, major dependencies, or architectural decisions.
    - `APP.md` : This file should contain an overview of the project's purpose, main features, and any relevant background information.
    - `ARCHITECTURE.md` : This file should describe the overall architecture of the project, including the design patterns used, the folder structure, and any important architectural decisions.
    - `FEATURES.md` : This file should list and describe each feature of the project, including any relevant details about how they work or how they are implemented.
    - `README.md` : This file should provide an overview of the project, including its purpose, main features, and any relevant background information.
    - `SETUP.md` : This file should contain instructions for setting up the development environment, including any dependencies that need to be installed and how to run the project locally.
    - `STACK.md` : This file should describe the technology stack used in the project, including any frameworks, libraries, or tools that are part of the project.
  - Inline doc comments (`///`) on any modified or newly created public type, method, or property.
- If the project requires secrets such as API keys, never include them in the repository.
- If the project uses Localizable.xcstrings, prefer to add user-facing strings using symbol keys (e.g. helloWorld) in the string catalog with `extractionState` set to "manual", accessing them via generated symbols such as  `Text(.helloWorld)`. Offer to translate new keys into all languages supported by the project.

## Pragmatic exceptions

- For prototypes or internal tools, a simpler route/service layout is acceptable if boundaries stay understandable.
- Prefer the safer operational choice when a production need conflicts with a style preference.