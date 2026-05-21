import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("LidarrWebhookHandler tests")
struct LidarrWebhookHandlerTests {
    @Test("Maps payload into normalized event")
    func mapsPayload() async throws {
        let handler = LidarrWebhookHandler()
        let payload = ByteBuffer(
            string:
            "{\"eventType\":\"AlbumAdded\",\"artist\":{\"name\":\"Daft Punk\"},\"album\":{\"title\":\"Discovery\"}}"
        )

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(event.source == "lidarr")
        #expect(event.eventType == "albumadded")
        #expect(event.summary == "[Lidarr] Album ajoute : Daft Punk - Discovery")
    }
}
