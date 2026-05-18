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
    app.http.server.configuration.port = 8090

    let configuration = configurationOverride ?? AppConfiguration.load(from: app.environment)

    let handlerRegistry = HandlerRegistry()
    handlerRegistry.register(BazarrWebhookHandler())
    handlerRegistry.register(RadarrWebhookHandler())
    handlerRegistry.register(SonarrWebhookHandler())
    handlerRegistry.register(LidarrWebhookHandler())
    handlerRegistry.register(ProwlarrWebhookHandler())
    handlerRegistry.register(Fail2banWebhookHandler())

    let channelRouter = IRCChannelRouter(routes: configuration.channelRoutes)

    let ircClient: any IRCClientProtocol
    if let ircClientOverride {
        ircClient = ircClientOverride
    } else {
        let connectedClient = IRCClient(
            configuration: configuration.irc,
            channels: channelRouter.allChannels(),
            eventLoopGroup: app.eventLoopGroup,
            logger: app.logger
        )
        try await connectedClient.start()
        ircClient = connectedClient
    }

    let dispatcher = WebhookDispatcher(
        handlerRegistry: handlerRegistry,
        channelRouter: channelRouter,
        ircClient: ircClient
    )
    let useCase = ProcessWebhookUseCase(dispatcher: dispatcher)

    app.middleware.use(RequestIDMiddleware())
    // Auth middleware supprimé : plus d'authentification par token

    // Initialize the official Vapor OpenAPI transport for future generated handlers.
    _ = VaporTransport(routesBuilder: app)

    try routes(
        app,
        processWebhookUseCase: useCase,
        swaggerEnabled: configuration.swaggerEnabled
    )
}
