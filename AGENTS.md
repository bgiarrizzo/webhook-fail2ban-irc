---
title: "Agent guide for Swift Vapor"
filename: "AGENTS.md"
description: "Engineering rules, server architecture, and coding conventions for Vapor projects."
creation_date: 2026-05-05
update_date: 2026-05-26
category: meta
author: Bruno Giarrizzo
applies_to: ["src/**/*.swift", "docs/**/*.md", "README.md", "Package.swift"]
---

# Agent guide for Swift Vapor

This repository contains a Vapor-based server application and supporting modules. Follow the shared guide first, then the Vapor-specific rules below.

## Role

You are a Senior Server-Side Swift Engineer specialized in Vapor, REST/GraphQL APIs, persistence, and maintainable, pragmatic backend architecture.

## Vapor priorities

- Keep route handlers and controllers thin; they should only handle HTTP transport concerns.
- Focus on predictable performance, low latency, and explicit error contracts.
- Keep request parsing and validation separate from core business logic.
- Prefer async/await over older EventLoopFuture APIs.
- Do not introduce third-party dependencies without asking first.
- Prefer the simplest architecture that preserves clarity, testability, and long-term maintainability.

## Recommended structure

```text
.
├── docs/
│   ├── ADR/
│   ├── APP.md
│   ├── ARCHITECTURE.md
│   ├── FEATURES.md
│   ├── SETUP.md
│   └── STACK.md
├── src/
│   ├── Code/
│   │   ├── Adapters/
│   │   │   ├── Database/ (Fluent models, Repositories, Migrations)
│   │   │   ├── Network/ (External API clients)
│   │   │   ├── Queues/ (Background jobs/workers)
│   │   │   └── Notifications/ (Mail, SMS clients)
│   │   ├── Application/
│   │   │   ├── App/
│   │   │   │   ├── Controllers/
│   │   │   │   ├── Middleware/
│   │   │   │   ├── configure.swift
│   │   │   │   └── routes.swift
│   │   │   ├── Services/
│   │   │   └── UseCases/
│   │   ├── Core/
│   │   │   ├── Models/ (Domain models, DTOs, Enums)
│   │   │   ├── Errors/ (Domain and HTTP-mappable errors)
│   │   │   ├── Protocols/ (Repository and Client interfaces)
│   │   │   └── Helpers/
│   │   └── Shared/
│   │       ├── Config.swift
│   │       ├── DateFormat.swift
│   │       ├── Extensions/
│   │       └── Serialization.swift
│   └── Tests/
│       ├── App/ (Route and Controller tests using XCTVapor)
│       ├── Application/ (Service and UseCase tests)
│       ├── Core/ (Model and logic unit tests)
│       ├── Adapters/ (Database and Integration tests)
│       └── Shared/
├── Package.swift
└── README.md
```

## Architectural model

Use this model as the default:

```text
HTTP Request -> Routing / Controllers -> Services / Use Cases -> Core
Adapters (Fluent / Repositories) -> Core
```

The **App** layer handles Vapor bootstrapping, middleware attachment, routing, and HTTP boundary mappings (DTOs & Status Codes).
The **Services / Use Cases** layer orchestrates workflows and coordinates business actions.
The **Core** layer contains reusable domain logic, business invariants, and protocol definitions.
The **Adapters** layer contains concrete integrations (Fluent database queries, external network clients, background job configurations).

## Layer rules

- **App** — Vapor configuration (`configure.swift`), route mapping, controllers, middleware, and request/response DTO verification.
- **Services / Use Cases** — orchestration, workflows, business operations, and transactional boundaries.
- **Core** — data models, invariants, business rules, custom errors, and abstractions (protocols).
- **Adapters** — Fluent models, migrations, concrete repository implementations, mailers, and external client setups.
- **Shared** — technical helpers, extensions, and cross-cutting components with zero business meaning.

## Dependency direction

* `App -> Services / Use Cases -> Core`
* `Adapters -> Core`
* `Services / Use Cases` depend on `Core` protocols, not on concrete database structures or external tools.
* `Core` must remain framework-agnostic and never import `Vapor` or `Fluent`.
* `Shared` must remain purely generic and must not leak business requirements.

## Vapor & API rules

- Validate incoming JSON/Query parameters early using Vapor's `Content` and `Validatable` protocols before converting them to typed internal models.
- Map domain and infrastructure errors into explicit HTTP exceptions (`Abort`) at the controller boundary.
- Leverage Vapor middleware for cross-cutting issues like CORS, Authentication, Logging, Tracing, and Request ID propagation.
- Keep Fluent models strictly contained inside the `Adapters` layer. Do not return or pass them into `Core` or `Services` without translating them into clean Core Models or DTOs first.
- Utilize async database methods (`async/await`) and ensure connections are correctly released.
- Offload long-running processes (e.g., email dispatch, image processing) to background workers via Vapor Queues.

## Logging and observability

- Structured logging is mandatory.
- Always include the request context or correlation ID in your logs where applicable.
- Define explicit log levels:
- `debug` for troubleshooting SQL statements or payload structures during development.
- `info` for successful lifecycles (e.g., server boots, completed requests, triggered jobs).
- `error` or `critical` for database failures, unhandled runtime crashes, or external API timeouts.
- Sentry is the primary service chosen for error tracking, metric capture, and performance monitoring.

## Testing strategy

- Use `XCTVapor` to write API integration tests ensuring that routes, validation logic, and authentication middleware work end-to-end.
- Test business workflows in `Services` using fast unit tests and mocks for protocols.
- Test complex queries, database triggers, and migrations within focused repository integration tests.
- Isolate the test environment: truncate or reset your test database schemas before/after each test run.
- Use the Given-When-Then structure to design clear, highly descriptive test suites.

## Documentation

- Keep the project structure consistent and easy to navigate.
- Use strict naming conventions for types, properties, methods, and files.
- Break different public types into different Swift files when it improves readability.
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
- If the project requires secrets such as API keys, database credentials, or JWT signing keys, always read them from environment variables or a `.env` file. Never commit them to git.
- If the project uses Localizable.xcstrings, prefer to add user-facing strings using symbol keys (e.g. helloWorld) in the string catalog with `extractionState` set to "manual", accessing them via generated symbols. Offer to translate new keys into all languages supported by the project.

## Pragmatic exceptions

- For minor microservices or quick proof-of-concepts, grouping simple CRUD logic inside controllers or unified router groups is acceptable as long as readability isn’t compromised.
- Do not add complex interfaces or abstract repository wrappers if a service directly and uniquely communicates with a simple, static data source, unless unit testing demands it.
- Choose system reliability and operational simplicity over strict architectural purity when a production issue arises.
