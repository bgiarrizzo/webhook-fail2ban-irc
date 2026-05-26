import Testing
@testable import webhooks2irc

@Suite("IRCConnectionConfiguration tests")
struct IRCConnectionConfigurationTests {
    @Test("Stores initializer values")
    func storesInitializerValues() {
        let configuration = IRCConnectionConfiguration(
            host: "irc.example.net",
            port: 6667,
            nick: "relay",
            password: "secret"
        )

        #expect(configuration.host == "irc.example.net")
        #expect(configuration.port == 6667)
        #expect(configuration.nick == "relay")
        #expect(configuration.password == "secret")
    }
}
