/// Defines transport operations required to relay messages to IRC.
public protocol IRCClientProtocol: Sendable {
    /// Starts the IRC connection lifecycle.
    func start() async throws

    /// Sends one message to IRC.
    /// - Parameter message: Message to send.
    func send(_ message: IRCMessage) async throws
}
