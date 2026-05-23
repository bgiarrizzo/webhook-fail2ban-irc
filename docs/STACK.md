# STACK

## Languages and runtime
- Swift 6
- Vapor 4
- SwiftNIO 2
- swift-openapi-vapor 1.x

## Architecture style
- Layered architecture: App / Application / Domain / Infrastructure / Shared
- Async/await-first orchestration

## Transport
- HTTP ingress via Vapor routes and middleware
- IRC egress via raw TCP built with NIO

## Logging and monitoring

- SwiftLog for structured logging
- JSONLogger (`xcode-actions/json-logger`) as the primary JSONSeq log backend
- swift-sentry (`Sentry` product) for error monitoring
- Integration mode: conditional bootstrap in release builds when `SENTRY_DSN` is present
- Export scope: warning/error logs through `SentryLogHandler`, with JSON logs always enabled
- Correlation model: request-scoped metadata propagated from middleware to route/application/transport logs
- Troubleshooting scope: HTTP ingress, payload decoding, source routing, IRC connection lifecycle, and outbound delivery
- Custom Sentry contextual handler implements the SwiftLog `log(event:)` API for forward compatibility

## Testing
- Swift Testing package
- VaporTesting for integration tests

## Deployment artifacts
- Swift Package Manager executable target: webhooks2irc
- Dockerfile for containerized runtime

## Container build profile
- Multi-stage Docker build (`swift:6.3-bookworm` -> `debian:bookworm-slim`)
- BuildKit cache mounts for apt metadata and SwiftPM (`.swiftpm`, `.build`, SwiftPM cache)
- Reduced build context via `.dockerignore` and targeted Docker `COPY`
- Runtime binary stripped in release stage to lower final image size
