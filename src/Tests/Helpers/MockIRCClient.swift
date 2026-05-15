import Foundation

@testable import webhooks2irc

/// Test double that captures all outbound IRC messages.
public actor MockIRCClient: IRCClientProtocol {
    private var messages: [IRCMessage]

    /// Creates a mock IRC client.
    public init() {
        self.messages = []
    }

    /// No-op start for tests.
    public func start() async throws {}

    /// Captures one outbound message.
    /// - Parameter message: Message to capture.
    public func send(_ message: IRCMessage) async throws {
        messages.append(message)
    }

    /// Returns captured messages.
    /// - Returns: Captured IRC messages.
    public func capturedMessages() -> [IRCMessage] {
        messages
    }
}
