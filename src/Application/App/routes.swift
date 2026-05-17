import NIOCore
import Vapor

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
    app.get { _ async in
        "webhook-irc-relay"
    }

    if swaggerEnabled {
        app.get("openapi.json") { request async -> Response in
            let response = Response(
                status: .ok,
                body: .init(
                    string: openAPIDocumentJSON(
                        baseURL: request.application.http.server.configuration.hostname))
            )
            response.headers.replaceOrAdd(name: .contentType, value: "application/json")
            return response
        }

        app.get("swagger") { _ async -> Response in
            let response = Response(status: .ok, body: .init(string: swaggerHTMLPage))
            response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
            return response
        }
    }

    app.post("webhooks", ":source") { request async throws -> WebhookAcceptedResponse in
        guard let source = request.parameters.get("source") else {
            throw Abort(.badRequest, reason: "Missing source parameter")
        }

        guard let payload = request.body.data else {
            throw Abort(.badRequest, reason: "Missing request body")
        }

        do {
            let outcome = try await processWebhookUseCase.execute(
                source: source,
                payload: payload,
                headers: request.headers
            )

            return WebhookAcceptedResponse(
                status: "accepted",
                source: outcome.event.source,
                eventType: outcome.event.eventType,
                channel: outcome.channel.rawValue
            )
        } catch let error as WebhookError {
            throw mapWebhookError(error)
        } catch let error as IRCError {
            throw mapIRCError(error)
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
    """
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
    switch error {
    case .unknownSource(let source):
        return Abort(.notFound, reason: "Unknown source: \(source)")
    case .invalidPayload(let reason):
        return Abort(.badRequest, reason: reason)
    // case .unauthorized(let reason):
    //     return Abort(.unauthorized, reason: reason)
    }
}

private func mapIRCError(_ error: IRCError) -> Abort {
    switch error {
    case .disconnected:
        return Abort(.serviceUnavailable, reason: "IRC connection unavailable")
    case .connectionFailed(let reason):
        return Abort(.serviceUnavailable, reason: reason)
    case .sendFailed(let reason):
        return Abort(.serviceUnavailable, reason: reason)
    }
}
