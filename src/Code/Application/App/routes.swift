import NIOCore
import Vapor

private let routesLogger = Logger(label: "webhooks2irc.app.routes")

/// Registers HTTP routes for webhook ingestion.
/// - Parameters:
///   - app: Vapor application instance.
///   - processWebhookUseCase: Use case handling webhook processing.
///   - swaggerEnabled: Toggle for OpenAPI and Swagger endpoints.
func routes(
    _ app: Application,
    processWebhookUseCase: ProcessWebhookUseCase,
    swaggerEnabled: Bool
) throws {
    app.logger.notice("Registering routes", metadata: ["swagger_enabled": "\(swaggerEnabled)"])

    app.get { request async in
        request.logger.debug("Health endpoint hit", metadata: ["path": "\(request.url.path)"])
        return "webhook-irc-relay"
    }

    if swaggerEnabled {
        app.get("openapi.json") { request async -> Response in
            request.logger.debug(
                "OpenAPI JSON requested",
                metadata: [
                    "path": "\(request.url.path)",
                    "method": "\(request.method.rawValue)",
                ]
            )
            let response = Response(
                status: .ok,
                body: .init(
                    string: openAPIDocumentJSON(
                        baseURL: request.application.http.server.configuration.hostname
                    )
                )
            )
            response.headers.replaceOrAdd(name: .contentType, value: "application/json")
            return response
        }

        app.get("swagger") { request async -> Response in
            request.logger.debug(
                "Swagger UI requested",
                metadata: ["path": "\(request.url.path)"]
            )
            let response = Response(status: .ok, body: .init(string: swaggerHTMLPage))
            response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
            return response
        }
    }

    app.post("webhooks", ":source") { request async throws -> WebhookAcceptedResponse in
        guard let source = request.parameters.get("source") else {
            request.logger.warning("Missing source path parameter")
            throw Abort(.badRequest, reason: "Missing source parameter")
        }

        guard let payload = request.body.data else {
            request.logger.warning(
                "Missing request body",
                metadata: ["source": "\(source)"]
            )
            throw Abort(.badRequest, reason: "Missing request body")
        }

        request.logger.notice(
            "Webhook request received",
            metadata: [
                "source": "\(source)",
                "payload_bytes": "\(payload.readableBytes)",
                "content_type": "\(request.headers.first(name: .contentType) ?? "unknown")",
                "user_agent": "\(request.headers.first(name: .userAgent) ?? "unknown")",
                "remote_address": "\(request.remoteAddress?.description ?? "unknown")",
            ]
        )

        do {
            let outcome = try await processWebhookUseCase.execute(
                source: source,
                payload: payload,
                headers: request.headers
            )

            request.logger.info(
                "Webhook processed and relayed",
                metadata: [
                    "source": "\(outcome.event.source)",
                    "event_type": "\(outcome.event.eventType)",
                    "channel": "\(outcome.channel.rawValue)",
                ]
            )

            return WebhookAcceptedResponse(
                status: "accepted",
                source: outcome.event.source,
                eventType: outcome.event.eventType,
                channel: outcome.channel.rawValue
            )
        } catch let error as WebhookError {
            request.logger.warning(
                "Webhook processing failed with domain validation error",
                metadata: ["source": "\(source)", "error": "\(error)"]
            )
            throw mapWebhookError(error)
        } catch let error as IRCError {
            request.logger.error(
                "Webhook processing failed with IRC transport error",
                metadata: ["source": "\(source)", "error": "\(error)"]
            )
            throw mapIRCError(error)
        } catch {
            request.logger.error(
                "Webhook processing failed with unexpected error",
                metadata: ["source": "\(source)", "error": "\(error)"]
            )
            throw error
        }
    }
}

private let swaggerHTMLPage = """
<!doctype html>
<html lang="en">
    <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>webhook-irc-relay API docs</title>
        <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
        <style>
            body { margin: 0; background: #10141a; }
            #swagger-ui { max-width: 1200px; margin: 0 auto; }
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
        <script>
            window.onload = function () {
                SwaggerUIBundle({
                    url: '/openapi.json',
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    displayRequestDuration: true
                });
            };
        </script>
    </body>
</html>
"""

private func openAPIDocumentJSON(baseURL: String) -> String {
    routesLogger.debug("Generating OpenAPI document", metadata: ["base_url": "\(baseURL)"])
    return """
    {
        "openapi": "3.0.3",
        "info": {
            "title": "webhook-irc-relay API",
            "version": "1.0.0",
            "description": "Webhook ingress and IRC relay service"
        },
        "servers": [
            {
                "url": "http://\(baseURL):8080"
            }
        ],
        "paths": {
            "/webhooks/{source}": {
                "post": {
                    "summary": "Ingest and relay a webhook",
                    "parameters": [
                        {
                            "name": "source",
                            "in": "path",
                            "required": true,
                            "schema": { "type": "string" }
                        },
                        {
                            // "name": "X-Webhook-Token", // Auth supprimée
                            "in": "header",
                            "required": true,
                            "schema": { "type": "string" }
                        }
                    ],
                    "requestBody": {
                        "required": true,
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "object",
                                    "additionalProperties": true
                                }
                            }
                        }
                    },
                    "responses": {
                        "200": {
                            "description": "Accepted and relayed",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "status": { "type": "string" },
                                            "source": { "type": "string" },
                                            "eventType": { "type": "string" },
                                            "channel": { "type": "string" }
                                        }
                                    }
                                }
                            }
                        },
                        "400": { "description": "Invalid payload" },
                        // "401": { "description": "Invalid token" }, // Auth supprimée
                        "404": { "description": "Unknown source" },
                        "503": { "description": "IRC transport unavailable" }
                    }
                }
            }
        }
    }
    """
}

private func mapWebhookError(_ error: WebhookError) -> Abort {
    routesLogger.warning("Mapping webhook error", metadata: ["error": "\(error)"])
    switch error {
    case let .unknownSource(source):
        return Abort(.notFound, reason: "Unknown source: \(source)")
    case let .invalidPayload(reason):
        return Abort(.badRequest, reason: reason)
        // case .unauthorized(let reason):
        //     return Abort(.unauthorized, reason: reason)
    }
}

private func mapIRCError(_ error: IRCError) -> Abort {
    routesLogger.error("Mapping IRC error", metadata: ["error": "\(error)"])
    switch error {
    case .disconnected:
        return Abort(.serviceUnavailable, reason: "IRC connection unavailable")
    case let .connectionFailed(reason):
        return Abort(.serviceUnavailable, reason: reason)
    case let .sendFailed(reason):
        return Abort(.serviceUnavailable, reason: reason)
    }
}
