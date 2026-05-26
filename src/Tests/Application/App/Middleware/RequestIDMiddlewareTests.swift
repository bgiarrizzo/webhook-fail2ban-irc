import Testing
import Vapor
import VaporTesting
@testable import webhooks2irc

@Suite("RequestIDMiddleware tests")
struct RequestIDMiddlewareTests {
    @Test("Generates X-Request-Id header when missing")
    func generatesRequestIDHeader() async throws {
        try await withApp(configure: { app in
            app.middleware.use(RequestIDMiddleware())
            app.get("ping") { _ async in "pong" }
        }) { app in
            try await app.testing().test(
                .GET,
                "ping",
                afterResponse: { response async in
                    #expect(response.status == .ok)
                    #expect(response.headers.first(name: "X-Request-Id")?.isEmpty == false)
                }
            )
        }
    }

    @Test("Propagates X-Request-Id header when provided")
    func propagatesIncomingRequestIDHeader() async throws {
        try await withApp(configure: { app in
            app.middleware.use(RequestIDMiddleware())
            app.get("ping") { _ async in "pong" }
        }) { app in
            try await app.testing().test(
                .GET,
                "ping",
                beforeRequest: { request in
                    request.headers.replaceOrAdd(name: "X-Request-Id", value: "req-123")
                },
                afterResponse: { response async in
                    #expect(response.status == .ok)
                    #expect(response.headers.first(name: "X-Request-Id") == "req-123")
                }
            )
        }
    }
}
