import NIOCore
import NIOHTTP1
@testable import webhooks2irc

/// Minimal deterministic webhook handler used by dispatcher unit tests.
struct TestWebhookHandler: WebhookHandlerProtocol {
    let sourceIdentifier: String = "radarr"

    func handle(payload _: ByteBuffer, headers _: HTTPHeaders) async throws -> WebhookEvent {
        WebhookEvent(
            source: "radarr",
            eventType: "download",
            summary: "[Radarr] synthetic event",
            metadata: [:],
            receivedAt: .init()
        )
    }
}
