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

## Testing
- Swift Testing package
- VaporTesting for integration tests

## Deployment artifacts
- Swift Package Manager executable target: webhooks2irc
- Dockerfile for containerized runtime
