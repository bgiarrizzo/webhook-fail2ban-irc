import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("ProcessWebhookUseCase tests")
struct ProcessWebhookUseCaseTests {
    @Test("Executes dispatch flow and returns event plus channel")
    func executesDispatchFlow() async throws {
        let registry = HandlerRegistry()
        registry.register(TestWebhookHandler())

        let router = IRCChannelRouter(routes: [
            "radarr": IRCChannel(rawValue: "#seedbox")
        ])
        let client = MockIRCClient()

        let dispatcher = WebhookDispatcher(
            handlerRegistry: registry,
            channelRouter: router,
            ircClient: client
        )
        let useCase = ProcessWebhookUseCase(dispatcher: dispatcher)

        let payload = ByteBuffer(string: "{}")
        let result = try await useCase.execute(source: "radarr", payload: payload, headers: HTTPHeaders())

        #expect(result.event.source == "radarr")
        #expect(result.channel.rawValue == "#seedbox")
        #expect(await client.capturedMessages().count == 1)
    }
}
