import Logging

/// Centralized source-to-channel router used as the single source of truth.
public final class IRCChannelRouter: Sendable {
    private let routes: [String: IRCChannel]
    private let logger = Logger(label: "webhooks2irc.application.channel-router")

    /// Creates a source-to-channel router.
    /// - Parameter routes: Mapping from source identifier to channel.
    public init(routes: [String: IRCChannel]) {
        self.routes = routes
        logger.info("Channel router initialized", metadata: ["routes_count": "\(routes.count)"])
    }

    /// Resolves the IRC channel for a source.
    /// - Parameter source: Source identifier.
    /// - Returns: Target channel.
    public func resolve(source: String) throws -> IRCChannel {
        let normalizedSource = source.lowercased()
        guard let channel = routes[normalizedSource] else {
            logger.warning("Channel route missing", metadata: ["source": "\(normalizedSource)"])
            throw WebhookError.unknownSource(source)
        }

        logger.debug(
            "Channel route resolved",
            metadata: ["source": "\(normalizedSource)", "channel": "\(channel.rawValue)"])

        return channel
    }

    /// Returns all unique channels declared by this router.
    /// - Returns: Distinct channel values.
    public func allChannels() -> Set<IRCChannel> {
        let channels = Set(routes.values)
        logger.debug("Resolved unique channels", metadata: ["count": "\(channels.count)"])
        return channels
    }
}
