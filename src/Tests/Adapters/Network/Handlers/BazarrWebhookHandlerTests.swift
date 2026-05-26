import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("BazarrWebhookHandler tests")
struct BazarrWebhookHandlerTests {
    @Test("Maps error payload into normalized event")
    func mapsPayload() async throws {
        let handler = BazarrWebhookHandler()
        let payload = ByteBuffer(
            string: "{\"eventType\":\"error\",\"message\":\"subtitle provider failed\"}"
        )

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(event.source == "bazarr")
        #expect(event.eventType == "error")
        #expect(event.summary == "[Bazarr] subtitle provider failed")
    }
}
