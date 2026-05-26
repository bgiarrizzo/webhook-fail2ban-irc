import Testing
@testable import webhooks2irc

@Suite("AppConfiguration tests")
struct AppConfigurationTests {
    @Test("Initializes with provided values")
    func initializesWithProvidedValues() {
        let configuration = AppConfiguration(
            irc: IRCConnectionConfiguration(host: "irc.example.net", port: 6697, nick: "relay", password: "pw"),
            channelRoutes: ["radarr": IRCChannel(rawValue: "#seedbox")],
            swaggerEnabled: true
        )

        #expect(configuration.irc.host == "irc.example.net")
        #expect(configuration.irc.port == 6697)
        #expect(configuration.irc.nick == "relay")
        #expect(configuration.channelRoutes["radarr"]?.rawValue == "#seedbox")
        #expect(configuration.swaggerEnabled == true)
    }
}
