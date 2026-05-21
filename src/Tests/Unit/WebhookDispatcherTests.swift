import NIOCore
import NIOHTTP1
import Testing
@testable import webhooks2irc

@Suite("WebhookDispatcher tests")
struct WebhookDispatcherTests {
    @Test("Dispatches message to routed channel")
    func dispatchesMessageToExpectedChannel() async throws {
        let registry = HandlerRegistry()
        registry.register(TestWebhookHandler())

        let router = IRCChannelRouter(routes: [
            "radarr": IRCChannel(rawValue: "#seedbox"),
        ])

        let mockClient = MockIRCClient()
        let dispatcher = WebhookDispatcher(
            handlerRegistry: registry,
            channelRouter: router,
            ircClient: mockClient
        )

        let payload = ByteBuffer(string: "{\"eventType\":\"download\"}")
        let result = try await dispatcher.dispatch(
            source: "radarr", payload: payload, headers: HTTPHeaders()
        )
        let messages = await mockClient.capturedMessages()

        #expect(result.channel.rawValue == "#seedbox")
        #expect(result.event.source == "radarr")
        #expect(messages.count == 1)
        #expect(messages.first?.channel.rawValue == "#seedbox")
        #expect(messages.first?.text == "[Radarr] synthetic event")
    }
}
