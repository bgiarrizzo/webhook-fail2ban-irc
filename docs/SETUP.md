---
title: "webhook-irc-relay - Setup guide"
filename: "SETUP.md"
description: "Installation, configuration, local run, testing, and container workflow for webhook-irc-relay."
creation_date: 2026-04-27
update_date: 2026-05-26
category: engineering
author: Bruno Giarrizzo
status: active
---

# webhook-irc-relay - Setup guide

> Get from a fresh clone to a running webhook-to-IRC relay in under 10 minutes.

---

## Table of contents

1. [Requirements](#1-requirements)
2. [Quick start](#2-quick-start)
3. [Project details](#3-project-details)
4. [Running from the command line](#4-running-from-the-command-line)
5. [Running tests](#5-running-tests)
6. [Environment and secrets](#6-environment-and-secrets)
7. [CI parity tips](#7-ci-parity-tips)
8. [Troubleshooting](#8-troubleshooting)
9. [Project conventions](#9-project-conventions)
10. [To be confirmed](#10-to-be-confirmed)

---

## 1. Requirements

| Tool | Minimum version | Notes |
|---|---|---|
| macOS or Linux | macOS 13+ or Vapor-compatible Linux | Host runtime for local development |
| Swift toolchain | 6.0+ | Required to build and run the executable |
| Docker (optional) | Recent stable version | Required only for containerized local run |
| Git | Recent stable version | Clone and version control |

No additional tools are required beyond Swift and optional Docker.

---

## 2. Quick start

```bash
# 1. Clone
git clone <repo-url>
cd webhook-fail2ban-irc

# 2. Build source package
cd src
swift build

# 3. Run the server
swift run
```

In the IDE:

1. Open the repository folder.
2. Open `src/Package.swift` if you want package-specific tooling.
3. Run `webhooks2irc` target from the Swift package.

> The first build resolves Swift Package dependencies and can take longer than subsequent runs.

---

## 3. Project details

| Setting | Value |
|---|---|
| Workspace root | `webhook-fail2ban-irc/` |
| Swift package (app) | `src/Package.swift` |
| Executable target | `webhooks2irc` |
| Source root | `src/Code/` |
| Test root | `src/Tests/` |
| Swift version | 6.x |
| Code signing style | Not applicable |
| Deployment style | Server process or Docker container |

### Build configurations

| Configuration | Usage |
|---|---|
| `debug` | Local development and diagnostics |
| `release` | Production-like validation and deployment |

---

## 4. Running from the command line

### Build only

```bash
cd src
swift build
```

### Build for release

```bash
cd src
swift build -c release
```

### Run the API locally

```bash
cd src
swift run
```

### Run with explicit release mode

```bash
cd src
swift run -c release
```

### Verify API documentation endpoints

- OpenAPI: `GET /openapi.json`
- Swagger UI: `GET /swagger`

---

## 5. Running tests

### In the IDE

Run tests from the Swift package test explorer for the `src` package.

### From the command line

```bash
cd src
swift test
```

### Target-specific notes

| Target | Framework | Coverage |
|---|---|---|
| `webhooks2ircTests` | Swift Testing and VaporTesting | Routes, handlers, dispatcher, router, and shared logging behavior |

Integration tests use app configuration overrides and mocks to avoid real IRC server dependencies during normal test runs.

---

## 6. Environment and secrets

### How configuration works

Runtime configuration is read from environment variables. Secrets must not be committed to git.

### Required variables

| Variable | Required | Description |
|---|---|---|
| `IRC_HOST` | Yes | IRC server hostname |
| `IRC_PORT` | Yes | IRC server port |
| `IRC_NICK` | Yes | Bot nickname |

### Optional variables

| Variable | Default | Description |
|---|---|---|
| `IRC_PASSWORD` | Empty | IRC password when required by server |
| `IRC_CHANNEL_SEEDBOX` | `#seedbox` | Channel for media automation sources |
| `IRC_CHANNEL_GIT` | `#git` | Channel for git-related sources |
| `IRC_CHANNEL_SYSOPS` | `#sysops` | Channel for security and ops alerts |
| `SWAGGER_ENABLED` | Auto by environment | Toggle API docs endpoints |
| `SENTRY_DSN` | Empty | Enables Sentry warning and error export in release mode |

### Sentry behavior

- Sentry starts only in release mode and only when `SENTRY_DSN` is defined.
- Logs continue to stream locally even when Sentry is enabled.
- Warning and error events include structured metadata and recent breadcrumbs.

---

## 7. CI parity tips

- Run `swift build -c release` locally before opening a release-related change.
- Run `swift test` from `src/` to match package root behavior.
- Validate environment variable presence in your shell profile or CI secret store.
- Keep Docker-based checks aligned with `docker/Dockerfile` build strategy.

---

## 8. Troubleshooting

- If webhook responses are `404`, verify the `:source` value matches a registered handler.
- If responses are `400`, inspect payload shape and source-specific required fields.
- If IRC delivery fails, verify host, port, nickname, and server credentials.
- If request tracing is missing, ensure `X-Request-Id` is provided or check middleware generation.
- If Sentry has no events, confirm release mode runtime and `SENTRY_DSN` availability.

---

## 9. Project conventions

- Keep route handlers thin and transport-focused.
- Keep source parsing in adapter handlers, not in route code.
- Keep domain contracts in Core and free from framework imports.
- Keep docs and ADRs updated whenever architecture or behavior changes.

---

## 10. To be confirmed

- Whether webhook request authentication is required in v2.
- Whether channel routing should move to external runtime config files.
- Whether production deployments should expose Swagger through authenticated access only.
