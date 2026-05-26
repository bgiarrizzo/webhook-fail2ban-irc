import Testing
@testable import webhooks2irc

@Suite("Entrypoint tests")
struct EntrypointTests {
    @Test("Entrypoint type is available")
    func entrypointTypeIsAvailable() {
        let type: Entrypoint.Type = Entrypoint.self
        #expect(type == Entrypoint.self)
    }
}
