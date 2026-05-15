import Vapor

/// Represents the transport response returned after successful webhook processing.
public struct WebhookAcceptedResponse: Content {
    /// Response status marker.
    public let status: String

    /// Processed source identifier.
    public let source: String

    /// Normalized event type.
    public let eventType: String

    /// Resolved target IRC channel.
    public let channel: String

    /// Creates a webhook accepted response payload.
    /// - Parameters:
    ///   - status: Status marker.
    ///   - source: Source identifier.
    ///   - eventType: Normalized event type.
    ///   - channel: Target IRC channel.
    public init(status: String, source: String, eventType: String, channel: String) {
        self.status = status
        self.source = source
        self.eventType = eventType
        self.channel = channel
    }
}
