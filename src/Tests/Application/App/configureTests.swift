import Testing
import VaporTesting
@testable import webhooks2irc

@Suite("configure tests")
struct ConfigureTests {
    @Test("Configures app with IRC override")
    func configuresAppWithOverrides() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: AppConfiguration(
                    irc: IRCConnectionConfiguration(host: "127.0.0.1", port: 6667, nick: "tests", password: nil),
                    channelRoutes: ["fail2ban": IRCChannel(rawValue: "#sysops")],
                    swaggerEnabled: false
                )
            )
        }) { app in
            try await app.testing().test(
                .GET,
                "",
                afterResponse: { response async in
                    #expect(response.status == .ok)
                }
            )
        }
    }
}
