import Logging
import NIOCore
import NIOHTTP1

/// Orchestrates handler resolution, channel routing, and IRC dispatch.
public final class WebhookDispatcher: @unchecked Sendable {
    private let handlerRegistry: HandlerRegistry
    private let channelRouter: IRCChannelRouter
    private let ircClient: any IRCClientProtocol
    private let logger = Logger(label: "webhooks2irc.application.webhook-dispatcher")

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
        let requestID = headers.first(name: "X-Request-Id") ?? "unknown"
        logger.notice(
            "Dispatch started",
            metadata: [
                "source": "\(source)",
                "payload_bytes": "\(payload.readableBytes)",
                "request_id": "\(requestID)",
            ])

        let handler = try handlerRegistry.resolve(source)
        logger.debug("Handler resolution completed", metadata: ["source": "\(source)"])

        let event = try await handler.handle(payload: payload, headers: headers)
        logger.debug(
            "Webhook event normalized",
            metadata: [
                "source": "\(event.source)",
                "event_type": "\(event.eventType)",
            ])

        let channel = try channelRouter.resolve(source: source)
        logger.debug(
            "Channel resolution completed",
            metadata: ["source": "\(source)", "channel": "\(channel.rawValue)"])

        let message = IRCMessage(channel: channel, text: event.summary.sanitizedForIRC())

        try await ircClient.send(message)
        logger.info(
            "Webhook dispatched to IRC",
            metadata: [
                "source": "\(source)",
                "event_type": "\(event.eventType)",
                "channel": "\(channel.rawValue)",
                "request_id": "\(requestID)",
            ])

        return (event: event, channel: channel)
    }
}
