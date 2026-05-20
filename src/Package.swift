// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "webhooks2irc",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 📘 OpenAPI bindings for Vapor.
        .package(url: "https://github.com/vapor/swift-openapi-vapor.git", from: "1.0.1"),
        // Sentry SDK for swift
        .package(url: "https://github.com/petrpavlik/swift-sentry.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "webhooks2irc",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "OpenAPIVapor", package: "swift-openapi-vapor"),
                .product(name: "SwiftSentry", package: "swift-sentry"),
            ],
            path: "Application",
            sources: ["App", "Domain", "Application", "Infrastructure", "Shared"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "webhooks2ircTests",
            dependencies: [
                .target(name: "webhooks2irc"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            path: "Tests",
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny")
    ]
}
