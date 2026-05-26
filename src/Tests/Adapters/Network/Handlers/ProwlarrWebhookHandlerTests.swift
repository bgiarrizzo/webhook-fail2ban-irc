import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("ProwlarrWebhookHandler tests")
struct ProwlarrWebhookHandlerTests {
    @Test("Maps payload into normalized event")
    func mapsPayload() async throws {
        let handler = ProwlarrWebhookHandler()
        let payload = ByteBuffer(
            string:
            "{\"eventType\":\"HealthIssue\",\"type\":\"IndexerError\",\"message\":\"timeout\",\"indexer\":{\"name\":\"Indexer-A\"}}"
        )

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(event.source == "prowlarr")
        #expect(event.eventType == "healthissue")
        #expect(event.summary == "[Prowlarr] Health Issue - IndexerError : timeout")
    }
}
