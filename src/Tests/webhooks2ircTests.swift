@testable import webhooks2irc
import VaporTesting
import Testing

@Suite("App Tests")
struct webhooks2ircTests {
    @Test("Test Root Route")
    func rootRoute() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: testConfiguration()
            )
        }) { app in
            try await app.testing().test(.GET, "", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "webhook-irc-relay")
            })
        }
    }
}

private func testConfiguration() -> AppConfiguration {
    AppConfiguration(
        irc: IRCConnectionConfiguration(
            host: "127.0.0.1",
            port: 6667,
            nick: "tests",
            password: nil
        ),
        channelRoutes: [:],
        swaggerEnabled: false
    )
}
