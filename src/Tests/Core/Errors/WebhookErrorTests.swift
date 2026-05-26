import Testing
@testable import webhooks2irc

@Suite("WebhookError tests")
struct WebhookErrorTests {
    @Test("Supports Equatable conformance")
    func supportsEquatable() {
        #expect(WebhookError.unknownSource("x") == .unknownSource("x"))
        #expect(WebhookError.invalidPayload("bad") == .invalidPayload("bad"))
    }
}
