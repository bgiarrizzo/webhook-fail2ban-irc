import Foundation
import Vapor

/// Assigns a request ID and propagates it in both request context and response headers.
public struct RequestIDMiddleware: AsyncMiddleware {
    /// Creates a request ID middleware.
    public init() {}

    /// Adds a request ID to the current request and response.
    /// - Parameters:
    ///   - request: Incoming request.
    ///   - next: Next responder.
    /// - Returns: Response from the next middleware/handler.
    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws
        -> Response
    {
        let startedAt = DispatchTime.now().uptimeNanoseconds
        let incomingRequestID = request.headers.first(name: "X-Request-Id")
        let requestID = request.headers.first(name: "X-Request-Id") ?? UUID().uuidString
        request.logger[metadataKey: "request_id"] = .string(requestID)
        request.logger[metadataKey: "method"] = .string(request.method.string)
        request.logger[metadataKey: "path"] = .string(request.url.path)
        request.logger[metadataKey: "remote_address"] = .string(
            request.remoteAddress?.description ?? "unknown")

        request.logger.info(
            "Incoming request",
            metadata: [
                "request_id_source": incomingRequestID == nil ? "generated" : "header",
                "query": "\(request.url.query ?? "")",
                "user_agent": "\(request.headers.first(name: .userAgent) ?? "unknown")",
            ])

        do {
            let response = try await next.respond(to: request)
            response.headers.replaceOrAdd(name: "X-Request-Id", value: requestID)

            let elapsedMs = (DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000
            request.logger.info(
                "Request completed",
                metadata: [
                    "status": "\(response.status.code)",
                    "duration_ms": "\(elapsedMs)",
                ])
            return response
        } catch {
            let elapsedMs = (DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000
            request.logger.error(
                "Request failed",
                metadata: [
                    "duration_ms": "\(elapsedMs)",
                    "error": "\(error)",
                ])
            throw error
        }
    }
}
