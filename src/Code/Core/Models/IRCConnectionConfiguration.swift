/// Runtime configuration for the IRC TCP connection.
public struct IRCConnectionConfiguration: Sendable {
    /// IRC host name or IP address.
    public let host: String

    /// IRC TCP port.
    public let port: Int

    /// IRC nickname used by the relay.
    public let nick: String

    /// Optional IRC server password.
    public let password: String?

    /// Creates an IRC connection configuration.
    /// - Parameters:
    ///   - host: IRC host.
    ///   - port: IRC port.
    ///   - nick: IRC nick.
    ///   - password: Optional IRC password.
    public init(host: String, port: Int, nick: String, password: String?) {
        self.host = host
        self.port = port
        self.nick = nick
        self.password = password
    }
}
