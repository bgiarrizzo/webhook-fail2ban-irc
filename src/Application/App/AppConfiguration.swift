import Vapor

/// Holds all runtime configuration required by the relay service.

public struct AppConfiguration: Sendable {
    /// IRC connection settings.
    public let irc: IRCConnectionConfiguration

    /// Source-to-channel mapping used by the channel router.
    public let channelRoutes: [String: IRCChannel]

    /// Controls whether OpenAPI and Swagger routes are exposed.
    public let swaggerEnabled: Bool

    /// Creates an app configuration instance.
    /// - Parameters:
    ///   - irc: IRC connection settings.
    ///   - channelRoutes: Source-to-channel route mapping.
    ///   - swaggerEnabled: Toggle for OpenAPI and Swagger endpoints.
    public init(
        irc: IRCConnectionConfiguration,
        channelRoutes: [String: IRCChannel],
        swaggerEnabled: Bool
    ) {
        self.irc = irc
        self.channelRoutes = channelRoutes
        self.swaggerEnabled = swaggerEnabled
    }

    /// Loads app configuration from process environment.
    /// - Parameter environment: Vapor environment accessor.
    /// - Returns: Fully initialized app configuration.
    public static func load(from environment: Environment) -> AppConfiguration {
        let seedbox = Environment.get("IRC_CHANNEL_SEEDBOX") ?? "#seedbox"
        let git = Environment.get("IRC_CHANNEL_GIT") ?? "#git"
        let sysops = Environment.get("IRC_CHANNEL_SYSOPS") ?? "#sysops"

        let host = Environment.get("IRC_HOST") ?? "127.0.0.1"
        let port = Int(Environment.get("IRC_PORT") ?? "6667") ?? 6667
        let nick = Environment.get("IRC_NICK") ?? "cloe"
        let password = Environment.get("IRC_PASSWORD")

        let routes: [String: IRCChannel] = [
            "bazarr": IRCChannel(rawValue: seedbox),
            "radarr": IRCChannel(rawValue: seedbox),
            "sonarr": IRCChannel(rawValue: seedbox),
            "lidarr": IRCChannel(rawValue: seedbox),
            "prowlarr": IRCChannel(rawValue: seedbox),
            "fail2ban": IRCChannel(rawValue: sysops),
            "github": IRCChannel(rawValue: git),
            "gitlab": IRCChannel(rawValue: git),
            "forgejo": IRCChannel(rawValue: git),
            "gitea": IRCChannel(rawValue: git),
        ]

        let defaultSwaggerEnabled = environment.name != "production"
        let swaggerEnabled = parseBool(Environment.get("SWAGGER_ENABLED")) ?? defaultSwaggerEnabled

        return AppConfiguration(
            irc: IRCConnectionConfiguration(host: host, port: port, nick: nick, password: password),
            channelRoutes: routes,
            swaggerEnabled: swaggerEnabled
        )
    }
}

private func parseBool(_ raw: String?) -> Bool? {
    guard let raw else {
        return nil
    }

    switch raw.lowercased() {
    case "1", "true", "yes", "on":
        return true
    case "0", "false", "no", "off":
        return false
    default:
        return nil
    }
}
