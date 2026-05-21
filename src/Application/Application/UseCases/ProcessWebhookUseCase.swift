import Logging
import NIOCore
import NIOHTTP1

/// Use case responsible for processing and relaying incoming webhooks.
public final class ProcessWebhookUseCase: @unchecked Sendable {
    private let dispatcher: WebhookDispatcher
    private let logger = Logger(label: "webhooks2irc.application.process-webhook-usecase")

    /// Creates a process webhook use case.
    /// - Parameter dispatcher: Dispatcher orchestrating the workflow.
    public init(dispatcher: WebhookDispatcher) {
        self.dispatcher = dispatcher
    }

    /// Executes the webhook processing flow.
    /// - Parameters:
    ///   - source: Source identifier.
    ///   - payload: Raw payload body.
    ///   - headers: Request headers.
    /// - Returns: The normalized event and routed channel.
    public func execute(
        source: String,
        payload: ByteBuffer,
        headers: HTTPHeaders
    ) async throws -> (event: WebhookEvent, channel: IRCChannel) {
        let requestID = headers.first(name: "X-Request-Id") ?? "unknown"
        logger.debug(
            "Use case execution started",
            metadata: [
                "source": "\(source)",
                "payload_bytes": "\(payload.readableBytes)",
                "request_id": "\(requestID)",
            ]
        )

        do {
            let outcome = try await dispatcher.dispatch(
                source: source, payload: payload, headers: headers
            )
            logger.info(
                "Use case execution completed",
                metadata: [
                    "source": "\(source)",
                    "event_type": "\(outcome.event.eventType)",
                    "channel": "\(outcome.channel.rawValue)",
                    "request_id": "\(requestID)",
                ]
            )
            return outcome
        } catch {
            logger.error(
                "Use case execution failed",
                metadata: [
                    "source": "\(source)",
                    "request_id": "\(requestID)",
                    "error": "\(error)",
                ]
            )
            throw error
        }
    }
}
