import Testing
@testable import webhooks2irc

@Suite("WebhookAcceptedResponse tests")
struct WebhookAcceptedResponseTests {
    @Test("Stores initializer values")
    func storesInitializerValues() {
        let response = WebhookAcceptedResponse(
            status: "accepted",
            source: "fail2ban",
            eventType: "ban",
            channel: "#sysops"
        )

        #expect(response.status == "accepted")
        #expect(response.source == "fail2ban")
        #expect(response.eventType == "ban")
        #expect(response.channel == "#sysops")
    }
}
