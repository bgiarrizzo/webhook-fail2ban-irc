import Testing
@testable import webhooks2irc

@Suite("IRCClientProtocol tests")
struct IRCClientProtocolTests {
    @Test("Protocol can be used as existential")
    func protocolCanBeUsedAsExistential() async throws {
        let client: any IRCClientProtocol = DummyIRCClient()

        try await client.start()
        try await client.send(IRCMessage(channel: IRCChannel(rawValue: "#seedbox"), text: "ping"))

        #expect(await (client as! DummyIRCClient).capturedCount == 1)
    }
}

private actor DummyIRCClient: IRCClientProtocol {
    private(set) var capturedCount: Int = 0

    func start() async throws {}

    func send(_ message: IRCMessage) async throws {
        _ = message
        capturedCount += 1
    }
}
