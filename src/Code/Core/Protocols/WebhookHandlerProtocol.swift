import NIOCore
import NIOHTTP1

/// Defines the contract for source-specific webhook payload normalization.
public protocol WebhookHandlerProtocol: Sendable {
    /// Stable source identifier used for registry resolution.
    var sourceIdentifier: String { get }

    /// Decodes and normalizes an incoming payload into a domain event.
    /// - Parameters:
    ///   - payload: Raw HTTP request body.
    ///   - headers: HTTP headers associated with the webhook call.
    /// - Returns: A normalized webhook event.
    func handle(payload: ByteBuffer, headers: HTTPHeaders) async throws -> WebhookEvent
}
