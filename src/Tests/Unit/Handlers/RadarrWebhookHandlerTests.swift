import NIOCore
import NIOHTTP1
import Testing

@testable import webhooks2irc

@Suite("RadarrWebhookHandler tests")
struct RadarrWebhookHandlerTests {
    @Test("Maps payload into normalized event")
    func mapsPayload() async throws {
        let handler = RadarrWebhookHandler()
        let payload = ByteBuffer(
            string:
                "{\"eventType\":\"MovieAdded\",\"movie\":{\"title\":\"Dune\",\"year\":2021,\"tmdbId\":438631}}"
        )

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(event.source == "radarr")
        #expect(event.eventType == "movieadded")
        #expect(
            event.summary
                == "[Radarr] Film ajoute : Dune (2021) - https://www.themoviedb.org/movie/438631")
    }
}
