import Testing
@testable import webhooks2irc

@Suite("HandlerRegistry tests")
struct HandlerRegistryTests {
    @Test("Resolves registered handler case insensitively")
    func resolvesRegisteredHandlerCaseInsensitively() throws {
        let registry = HandlerRegistry()
        let handler = TestWebhookHandler()
        registry.register(handler)

        let resolved = try registry.resolve("RADARR")

        #expect(resolved.sourceIdentifier == "radarr")
    }

    @Test("Throws unknownSource for non-registered source")
    func throwsUnknownSource() {
        let registry = HandlerRegistry()

        #expect(throws: WebhookError.unknownSource("missing")) {
            _ = try registry.resolve("missing")
        }
    }
}
