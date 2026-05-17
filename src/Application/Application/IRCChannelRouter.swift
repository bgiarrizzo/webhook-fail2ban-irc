/// Centralized source-to-channel router used as the single source of truth.
public final class IRCChannelRouter: Sendable {
    private let routes: [String: IRCChannel]

    /// Creates a source-to-channel router.
    /// - Parameter routes: Mapping from source identifier to channel.
    public init(routes: [String: IRCChannel]) {
        self.routes = routes
    }

    /// Resolves the IRC channel for a source.
    /// - Parameter source: Source identifier.
    /// - Returns: Target channel.
    public func resolve(source: String) throws -> IRCChannel {
        guard let channel = routes[source.lowercased()] else {
            throw WebhookError.unknownSource(source)
        }

        return channel
    }

    /// Returns all unique channels declared by this router.
    /// - Returns: Distinct channel values.
    public func allChannels() -> Set<IRCChannel> {
        Set(routes.values)
    }
}
