import Foundation
import Testing
@testable import webhooks2irc

@Suite("WebhookEvent tests")
struct WebhookEventTests {
    @Test("Stores initializer values")
    func storesInitializerValues() {
        let now = Date()
        let event = WebhookEvent(
            source: "radarr",
            eventType: "download",
            summary: "Movie downloaded",
            metadata: ["movie": "Dune"],
            receivedAt: now
        )

        #expect(event.source == "radarr")
        #expect(event.eventType == "download")
        #expect(event.summary == "Movie downloaded")
        #expect(event.metadata["movie"] == "Dune")
        #expect(event.receivedAt == now)
    }
}
