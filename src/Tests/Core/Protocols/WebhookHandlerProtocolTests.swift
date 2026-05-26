import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("WebhookHandlerProtocol tests")
struct WebhookHandlerProtocolTests {
    @Test("Protocol contract can normalize payload")
    func protocolContractCanNormalizePayload() async throws {
        let handler: any WebhookHandlerProtocol = DummyWebhookHandler()
        let payload = ByteBuffer(string: "{}")

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(handler.sourceIdentifier == "dummy")
        #expect(event.source == "dummy")
        #expect(event.eventType == "test")
    }
}

private struct DummyWebhookHandler: WebhookHandlerProtocol {
    let sourceIdentifier: String = "dummy"

    func handle(payload _: ByteBuffer, headers _: HTTPHeaders) async throws -> WebhookEvent {
        WebhookEvent(
            source: "dummy",
            eventType: "test",
            summary: "ok",
            metadata: [:],
            receivedAt: .init()
        )
    }
}
