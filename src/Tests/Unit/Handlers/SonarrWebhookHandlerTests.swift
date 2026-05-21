import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("SonarrWebhookHandler tests")
struct SonarrWebhookHandlerTests {
    @Test("Maps payload into normalized event")
    func mapsPayload() async throws {
        let handler = SonarrWebhookHandler()
        let payload = ByteBuffer(
            string:
            "{\"eventType\":\"Download\",\"series\":{\"title\":\"Severance\"},\"episodes\":[{\"seasonNumber\":1,\"episodeNumber\":2}],\"release\":{\"releaseTitle\":\"Severance.S01E02.1080p\"}}"
        )

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(event.source == "sonarr")
        #expect(event.eventType == "download")
        #expect(
            event.summary
                == "[Sonarr] Episode telecharge : Severance S01E02 - Severance.S01E02.1080p"
        )
    }
}
