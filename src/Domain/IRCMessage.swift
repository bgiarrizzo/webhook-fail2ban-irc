/// Represents a formatted IRC message ready to be sent.
public struct IRCMessage: Sendable, Equatable {
    /// Destination IRC channel.
    public let channel: IRCChannel

    /// Message text content.
    public let text: String

    /// Creates an IRC message.
    /// - Parameters:
    ///   - channel: Destination channel.
    ///   - text: Message content.
    public init(channel: IRCChannel, text: String) {
        self.channel = channel
        self.text = text
    }
}
