import Testing
@testable import webhooks2irc

@Suite("IRCChannelRouter tests")
struct IRCChannelRouterTests {
    @Test("Resolves known source to expected channel")
    func resolvesKnownSource() throws {
        let router = IRCChannelRouter(routes: [
            "radarr": IRCChannel(rawValue: "#seedbox"),
            "fail2ban": IRCChannel(rawValue: "#sysops"),
        ])

        let channel = try router.resolve(source: "radarr")

        #expect(channel.rawValue == "#seedbox")
    }

    @Test("Throws for unknown source")
    func throwsForUnknownSource() {
        let router = IRCChannelRouter(routes: [
            "radarr": IRCChannel(rawValue: "#seedbox"),
        ])

        #expect(throws: WebhookError.unknownSource("unknown")) {
            _ = try router.resolve(source: "unknown")
        }
    }
}
