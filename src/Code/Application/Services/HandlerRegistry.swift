import Foundation
import Logging

/// Registers and resolves webhook handlers by source identifier.
public final class HandlerRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var handlers: [String: any WebhookHandlerProtocol]
    private let logger = Logger(label: "webhooks2irc.application.handler-registry")

    /// Creates an empty handler registry.
    public init() {
        handlers = [:]
        logger.debug("Handler registry initialized")
    }

    /// Registers a handler for its source identifier.
    /// - Parameter handler: Handler to register.
    public func register(_ handler: any WebhookHandlerProtocol) {
        lock.lock()
        defer { lock.unlock() }
        let source = handler.sourceIdentifier.lowercased()
        handlers[source] = handler
        logger.info(
            "Handler registered",
            metadata: ["source": "\(source)", "registered_handlers": "\(handlers.count)"]
        )
    }

    /// Resolves a handler for a source.
    /// - Parameter source: Source identifier.
    /// - Returns: Matching webhook handler.
    public func resolve(_ source: String) throws -> any WebhookHandlerProtocol {
        lock.lock()
        defer { lock.unlock() }

        let normalizedSource = source.lowercased()
        guard let handler = handlers[normalizedSource] else {
            logger.warning(
                "Handler not found for source",
                metadata: [
                    "source": "\(normalizedSource)", "registered_handlers": "\(handlers.count)",
                ]
            )
            throw WebhookError.unknownSource(source)
        }

        logger.debug("Handler resolved", metadata: ["source": "\(normalizedSource)"])

        return handler
    }
}
