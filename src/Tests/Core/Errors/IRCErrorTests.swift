import Testing
@testable import webhooks2irc

@Suite("IRCError tests")
struct IRCErrorTests {
    @Test("Supports Equatable conformance")
    func supportsEquatable() {
        #expect(IRCError.disconnected == .disconnected)
        #expect(IRCError.connectionFailed("x") == .connectionFailed("x"))
        #expect(IRCError.sendFailed("y") == .sendFailed("y"))
    }
}
