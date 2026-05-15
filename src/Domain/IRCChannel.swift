/// Represents a typed IRC destination channel.
public struct IRCChannel: RawRepresentable, Equatable, Hashable, Sendable {
    /// Raw channel value (for example #seedbox, #git, #sysops).
    public let rawValue: String

    /// Creates an IRC channel value object.
    /// - Parameter rawValue: Raw channel name.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
