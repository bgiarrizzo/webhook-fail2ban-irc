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
        let requestID = request.headers.first(name: "X-Request-Id") ?? UUID().uuidString
        request.logger[metadataKey: "request_id"] = .string(requestID)

        let response = try await next.respond(to: request)
        response.headers.replaceOrAdd(name: "X-Request-Id", value: requestID)
        return response
    }
}
