import Foundation
import NIOCore
import NIOHTTP1

/// Normalizes Fail2ban webhook payloads into domain events.
public struct Fail2banWebhookHandler: WebhookHandlerProtocol {
    /// Stable source identifier used by routing and registry.
    public let sourceIdentifier: String = "fail2ban"

    /// Creates a Fail2ban webhook handler.
    public init() {}

    /// Decodes and normalizes a Fail2ban payload.
    /// - Parameters:
    ///   - payload: Raw request body.
    ///   - headers: HTTP headers.
    /// - Returns: Normalized webhook event.
    public func handle(payload: ByteBuffer, headers: HTTPHeaders) async throws -> WebhookEvent {
        let decoded: Payload

        do {
            let data = try payloadData(from: payload)
            decoded = try JSONDecoder.webhookDecoder().decode(Payload.self, from: data)
        } catch {
            throw WebhookError.invalidPayload("Invalid Fail2ban payload")
        }

        let ipAddress = decoded.ip ?? "unknown"
        let jail = decoded.jail ?? "unknown"
        let eventType = (decoded.eventType ?? decoded.type ?? "ban").lowercased()
        let summary = "[Fail2ban] IP bannie : \(ipAddress) (jail: \(jail))"

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: ["ip": ipAddress, "jail": jail],
            receivedAt: Date()
        )
    }

    private struct Payload: Codable {
        let eventType: String?
        let type: String?
        let ip: String?
        let jail: String?
    }
}

private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
