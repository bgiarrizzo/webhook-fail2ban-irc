import OpenAPIVapor
import Vapor

/// Configures and wires the Vapor application.
/// - Parameters:
///   - app: Vapor application instance.
///   - ircClientOverride: Optional IRC client used mainly for tests.
public func configure(
    _ app: Application,
    ircClientOverride: (any IRCClientProtocol)? = nil,
    configurationOverride: AppConfiguration? = nil
) async throws {
    let configuration = configurationOverride ?? AppConfiguration.load(from: app.environment)
    app.logger.notice(
        "Runtime configuration loaded",
        metadata: [
            "environment": "\(app.environment.name)",
            "irc_host": "\(configuration.irc.host)",
            "irc_port": "\(configuration.irc.port)",
            "irc_nick": "\(configuration.irc.nick)",
            "irc_password_configured": "\(configuration.irc.password?.isEmpty == false)",
            "swagger_enabled": "\(configuration.swaggerEnabled)",
            "channel_routes_count": "\(configuration.channelRoutes.count)",
        ]
    )

    let handlerRegistry = HandlerRegistry()
    handlerRegistry.register(BazarrWebhookHandler())
    handlerRegistry.register(RadarrWebhookHandler())
    handlerRegistry.register(SonarrWebhookHandler())
    handlerRegistry.register(LidarrWebhookHandler())
    handlerRegistry.register(ProwlarrWebhookHandler())
    handlerRegistry.register(Fail2banWebhookHandler())
    app.logger.info("Webhook handlers registered")

    let channelRouter = IRCChannelRouter(routes: configuration.channelRoutes)

    let ircClient: any IRCClientProtocol
    if let ircClientOverride {
        app.logger.notice("Using IRC client override")
        ircClient = ircClientOverride
    } else {
        app.logger.notice("Creating IRC client and attempting initial connection")
        let connectedClient = IRCClient(
            configuration: configuration.irc,
            channels: channelRouter.allChannels(),
            eventLoopGroup: app.eventLoopGroup,
            logger: app.logger
        )
        try await connectedClient.start()
        app.logger.notice("IRC client connected")
        ircClient = connectedClient
    }

    let dispatcher = WebhookDispatcher(
        handlerRegistry: handlerRegistry,
        channelRouter: channelRouter,
        ircClient: ircClient
    )
    let useCase = ProcessWebhookUseCase(dispatcher: dispatcher)

    app.middleware.use(RequestIDMiddleware())
    app.logger.info("Request ID middleware installed")
    // Auth middleware supprimé : plus d'authentification par token

    // Initialize the official Vapor OpenAPI transport for future generated handlers.
    _ = VaporTransport(routesBuilder: app)
    app.logger.info("OpenAPI transport initialized")

    try routes(
        app,
        processWebhookUseCase: useCase,
        swaggerEnabled: configuration.swaggerEnabled
    )
    app.logger.notice("HTTP routes registered")
}
