import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("Fail2banWebhookHandler tests")
struct Fail2banWebhookHandlerTests {
    @Test("Maps payload into normalized event")
    func mapsPayload() async throws {
        let handler = Fail2banWebhookHandler()
        let payload = ByteBuffer(
            string: "{\"type\":\"ban\",\"ip\":\"203.0.113.10\",\"jail\":\"sshd\"}"
        )

        let event = try await handler.handle(payload: payload, headers: HTTPHeaders())

        #expect(event.source == "fail2ban")
        #expect(event.eventType == "ban")
        #expect(event.summary == "[Fail2ban] IP bannie : 203.0.113.10 (jail: sshd)")
    }
}
