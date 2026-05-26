import Testing
@testable import webhooks2irc

@Suite("IRCChannel tests")
struct IRCChannelTests {
    @Test("Stores raw value")
    func storesRawValue() {
        let channel = IRCChannel(rawValue: "#seedbox")
        #expect(channel.rawValue == "#seedbox")
    }
}
