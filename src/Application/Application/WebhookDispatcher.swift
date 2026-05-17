import NIOCore
import NIOHTTP1

/// Orchestrates handler resolution, channel routing, and IRC dispatch.
public final class WebhookDispatcher: @unchecked Sendable {
    private let handlerRegistry: HandlerRegistry
    private let channelRouter: IRCChannelRouter
    private let ircClient: any IRCClientProtocol

    /// Creates a webhook dispatcher.
    /// - Parameters:
    ///   - handlerRegistry: Registered source handlers.
    ///   - channelRouter: Source-to-channel router.
    ///   - ircClient: IRC transport port.
    public init(
        handlerRegistry: HandlerRegistry,
        channelRouter: IRCChannelRouter,
        ircClient: any IRCClientProtocol
    ) {
        self.handlerRegistry = handlerRegistry
        self.channelRouter = channelRouter
        self.ircClient = ircClient
    }

    /// Processes an incoming webhook and relays it to IRC.
    /// - Parameters:
    ///   - source: Source identifier.
    ///   - payload: Raw request payload.
    ///   - headers: Request headers.
    /// - Returns: The normalized event and the resolved target channel.
    public func dispatch(
        source: String,
        payload: ByteBuffer,
        headers: HTTPHeaders
    ) async throws -> (event: WebhookEvent, channel: IRCChannel) {
        let handler = try handlerRegistry.resolve(source)
        let event = try await handler.handle(payload: payload, headers: headers)
        let channel = try channelRouter.resolve(source: source)
        let message = IRCMessage(channel: channel, text: event.summary.sanitizedForIRC())

        try await ircClient.send(message)

        return (event: event, channel: channel)
    }
}
