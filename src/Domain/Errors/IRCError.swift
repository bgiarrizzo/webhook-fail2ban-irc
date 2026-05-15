/// Domain-level errors related to IRC transport behavior.
public enum IRCError: Error, Equatable, Sendable {
    /// No active IRC connection is available.
    case disconnected

    /// The client failed to establish an IRC connection.
    case connectionFailed(String)

    /// Message write operation failed.
    case sendFailed(String)
}
