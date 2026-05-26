import Testing
@testable import webhooks2irc

@Suite("IRCMessage tests")
struct IRCMessageTests {
    @Test("Stores channel and text")
    func storesChannelAndText() {
        let message = IRCMessage(channel: IRCChannel(rawValue: "#seedbox"), text: "hello")

        #expect(message.channel.rawValue == "#seedbox")
        #expect(message.text == "hello")
    }
}
