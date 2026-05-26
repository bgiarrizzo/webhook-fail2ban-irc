import NIOCore
import NIOHTTP1

/// Use case responsible for processing and relaying incoming webhooks.
public final class ProcessWebhookUseCase: @unchecked Sendable {
    private let dispatcher: WebhookDispatcher

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
        try await dispatcher.dispatch(source: source, payload: payload, headers: headers)
    }
}
