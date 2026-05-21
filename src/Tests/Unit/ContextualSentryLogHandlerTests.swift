import Logging
import Testing

@testable import webhooks2irc

@Suite("ContextualSentryLogHandler tests")
struct ContextualSentryLogHandlerTests {
    @Test("Normalizes Sentry metadata keys with ctx prefix")
    func normalizesSentryMetadataKeys() {
        let metadata: Logger.Metadata = [
            "request_id": "req-1",
            "X-Request-Id": "req-1",
            "breadcrumb_1": "one",
            "ctx_existing": "keep",
        ]

        let normalized = ContextualSentryLogHandler.normalizeMetadataForSentry(metadata)

        #expect(normalized["ctx_request_id"]?.description == "req-1")
        #expect(normalized["ctx_x_request_id"]?.description == "req-1")
        #expect(normalized["ctx_breadcrumb_1"]?.description == "one")
        #expect(normalized["ctx_existing"]?.description == "keep")
    }

    @Test("Scopes breadcrumbs by request_id when available")
    func scopesBreadcrumbsByRequestID() {
        let store = BreadcrumbTrailStore(capacity: 10)

        store.record(
            level: .info,
            label: "test.logger",
            message: "First request breadcrumb",
            metadata: ["request_id": "req-1", "source": "radarr"]
        )
        store.record(
            level: .info,
            label: "test.logger",
            message: "Second request breadcrumb",
            metadata: ["request_id": "req-2", "source": "sonarr"]
        )
        store.record(
            level: .debug,
            label: "test.logger",
            message: "Another first request breadcrumb",
            metadata: ["request_id": "req-1", "channel": "#seedbox"]
        )

        let metadata = store.metadataForEvent(metadata: ["request_id": "req-1"], limit: 5)

        #expect(metadata["breadcrumbs_scope"]?.description == "request_id")
        #expect(metadata["breadcrumb_count"]?.description == "2")
        #expect(metadata["breadcrumb_1"]?.description.contains("First request breadcrumb") == true)
        #expect(
            metadata["breadcrumb_2"]?.description.contains("Another first request breadcrumb")
                == true)
        #expect(
            metadata["breadcrumb_1"]?.description.contains("Second request breadcrumb") == false)
    }

    @Test("Falls back to global breadcrumbs when request_id has no trail")
    func fallsBackToGlobalBreadcrumbs() {
        let store = BreadcrumbTrailStore(capacity: 10)

        store.record(
            level: .info,
            label: "test.logger",
            message: "Global breadcrumb one",
            metadata: ["source": "radarr"]
        )
        store.record(
            level: .warning,
            label: "test.logger",
            message: "Global breadcrumb two",
            metadata: ["source": "fail2ban"]
        )

        let metadata = store.metadataForEvent(metadata: ["request_id": "missing"], limit: 5)

        #expect(metadata["breadcrumbs_scope"]?.description == "global-fallback")
        #expect(metadata["breadcrumb_count"]?.description == "2")
        #expect(metadata["breadcrumb_2"]?.description.contains("Global breadcrumb two") == true)
    }
}
