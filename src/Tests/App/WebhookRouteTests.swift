import Foundation
import Testing
import VaporTesting
@testable import webhooks2irc

@Suite("Webhook route integration tests")
struct WebhookRouteTests {
    @Test("Serves OpenAPI specification")
    func servesOpenAPISpecification() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration()
            )
        }) { app in
            try await app.testing().test(
                .GET, "openapi.json",
                afterResponse: { response async in
                    #expect(response.status == .ok)
                    #expect(
                        response.headers.contentType?.description.contains("application/json")
                            == true
                    )
                    #expect(response.body.string.contains("\"openapi\": \"3.0.3\""))
                    #expect(response.body.string.contains("/webhooks/{source}"))
                }
            )
        }
    }

    @Test("Does not serve Swagger when disabled")
    func doesNotServeSwaggerWhenDisabled() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration(swaggerEnabled: false)
            )
        }) { app in
            try await app.testing().test(
                .GET, "swagger",
                afterResponse: { response async in
                    #expect(response.status == .notFound)
                }
            )

            try await app.testing().test(
                .GET, "openapi.json",
                afterResponse: { response async in
                    #expect(response.status == .notFound)
                }
            )
        }
    }

    @Test("Serves Swagger UI page")
    func servesSwaggerUIPage() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration()
            )
        }) { app in
            try await app.testing().test(
                .GET, "swagger",
                afterResponse: { response async in
                    #expect(response.status == .ok)
                    #expect(response.headers.contentType?.description.contains("text/html") == true)
                    #expect(response.body.string.contains("SwaggerUIBundle"))
                    #expect(response.body.string.contains("/openapi.json"))
                }
            )
        }
    }

    @Test("Accepts valid webhook and relays to expected channel")
    func acceptsValidWebhook() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration()
            )
        }) { app in
            try await app.testing().test(
                .POST, "webhooks/fail2ban",
                beforeRequest: { request in
                    request.headers.replaceOrAdd(name: "Content-Type", value: "application/json")
                    request.headers.replaceOrAdd(name: "X-Webhook-Token", value: "secret-token")
                    request.body = .init(
                        string: "{\"type\":\"ban\",\"ip\":\"198.51.100.17\",\"jail\":\"sshd\"}"
                    )
                },
                afterResponse: { response async in
                    #expect(response.status == .ok)
                    if let data = response.body.string.data(using: .utf8),
                       let payload = try? JSONDecoder().decode(
                           WebhookAcceptedResponse.self, from: data
                       )
                    {
                        #expect(payload.status == "accepted")
                        #expect(payload.channel == "#sysops")
                    } else {
                        Issue.record("Unable to decode WebhookAcceptedResponse")
                    }
                }
            )

            let messages = await mockClient.capturedMessages()
            #expect(messages.count == 1)
            #expect(messages.first?.channel.rawValue == "#sysops")
        }
    }

    @Test("Accepts webhook even with a token header")
    func acceptsWebhookWithTokenHeader() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration()
            )
        }) { app in
            try await app.testing().test(
                .POST, "webhooks/fail2ban",
                beforeRequest: { request in
                    request.headers.replaceOrAdd(name: "Content-Type", value: "application/json")
                    request.headers.replaceOrAdd(name: "X-Webhook-Token", value: "wrong-token")
                    request.body = .init(
                        string: "{\"type\":\"ban\",\"ip\":\"203.0.113.10\",\"jail\":\"sshd\"}"
                    )
                },
                afterResponse: { response async in
                    #expect(response.status == .ok)
                }
            )

            let messages = await mockClient.capturedMessages()
            #expect(messages.count == 1)
            #expect(messages.first?.channel.rawValue == "#sysops")
        }
    }

    @Test("Returns not found for unknown source")
    func returnsNotFoundForUnknownSource() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration()
            )
        }) { app in
            try await app.testing().test(
                .POST, "webhooks/forgejo",
                beforeRequest: { request in
                    request.headers.replaceOrAdd(name: "Content-Type", value: "application/json")
                    request.headers.replaceOrAdd(name: "X-Webhook-Token", value: "token")
                    request.body = .init(string: "{}")
                },
                afterResponse: { response async in
                    #expect(response.status == .notFound)
                }
            )
        }
    }

    @Test("Returns bad request for invalid payload")
    func returnsBadRequestForInvalidPayload() async throws {
        let mockClient = MockIRCClient()

        try await withApp(configure: { app in
            try await configure(
                app,
                ircClientOverride: mockClient,
                configurationOverride: integrationTestConfiguration()
            )
        }) { app in
            try await app.testing().test(
                .POST, "webhooks/fail2ban",
                beforeRequest: { request in
                    request.headers.replaceOrAdd(name: "Content-Type", value: "application/json")
                    request.headers.replaceOrAdd(name: "X-Webhook-Token", value: "secret-token")
                    request.body = .init(string: "not-json")
                },
                afterResponse: { response async in
                    #expect(response.status == .badRequest)
                }
            )
        }
    }
}

private func integrationTestConfiguration(swaggerEnabled: Bool = true) -> AppConfiguration {
    AppConfiguration(
        irc: IRCConnectionConfiguration(
            host: "127.0.0.1", port: 6667, nick: "tests", password: nil
        ),
        channelRoutes: [
            "bazarr": IRCChannel(rawValue: "#seedbox"),
            "radarr": IRCChannel(rawValue: "#seedbox"),
            "sonarr": IRCChannel(rawValue: "#seedbox"),
            "lidarr": IRCChannel(rawValue: "#seedbox"),
            "prowlarr": IRCChannel(rawValue: "#seedbox"),
            "fail2ban": IRCChannel(rawValue: "#sysops"),
        ],
        swaggerEnabled: swaggerEnabled
    )
}
