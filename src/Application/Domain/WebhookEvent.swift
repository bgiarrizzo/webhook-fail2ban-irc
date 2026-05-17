import Foundation

/// Represents a normalized webhook event produced by a source-specific handler.
public struct WebhookEvent: Sendable, Equatable {
    /// Source identifier that produced this event.
    public let source: String

    /// Normalized event type for downstream processing.
    public let eventType: String

    /// Human-readable summary that can be relayed to IRC.
    public let summary: String

    /// Additional key/value metadata extracted from the payload.
    public let metadata: [String: String]

    /// Timestamp indicating when the relay received this event.
    public let receivedAt: Date

    /// Creates a normalized webhook event.
    /// - Parameters:
    ///   - source: Source identifier.
    ///   - eventType: Normalized event type.
    ///   - summary: Human-readable summary.
    ///   - metadata: Additional metadata.
    ///   - receivedAt: Receive timestamp.
    public init(
        source: String,
        eventType: String,
        summary: String,
        metadata: [String: String],
        receivedAt: Date
    ) {
        self.source = source
        self.eventType = eventType
        self.summary = summary
        self.metadata = metadata
        self.receivedAt = receivedAt
    }
}
