import Foundation

/// Registers and resolves webhook handlers by source identifier.
public final class HandlerRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var handlers: [String: any WebhookHandlerProtocol]

    /// Creates an empty handler registry.
    public init() {
        self.handlers = [:]
    }

    /// Registers a handler for its source identifier.
    /// - Parameter handler: Handler to register.
    public func register(_ handler: any WebhookHandlerProtocol) {
        lock.lock()
        defer { lock.unlock() }
        handlers[handler.sourceIdentifier.lowercased()] = handler
    }

    /// Resolves a handler for a source.
    /// - Parameter source: Source identifier.
    /// - Returns: Matching webhook handler.
    public func resolve(_ source: String) throws -> any WebhookHandlerProtocol {
        lock.lock()
        defer { lock.unlock() }

        guard let handler = handlers[source.lowercased()] else {
            throw WebhookError.unknownSource(source)
        }

        return handler
    }
}
