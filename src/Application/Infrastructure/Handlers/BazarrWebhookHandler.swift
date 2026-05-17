import Foundation
import NIOCore
import NIOHTTP1

/// Normalizes Bazarr webhook payloads into domain events.
public struct BazarrWebhookHandler: WebhookHandlerProtocol {
    /// Stable source identifier used by routing and registry.
    public let sourceIdentifier: String = "bazarr"

    /// Creates a Bazarr webhook handler.
    public init() {}

    /// Decodes and normalizes a Bazarr payload.
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
            throw WebhookError.invalidPayload("Invalid Bazarr payload")
        }

        let eventType = (decoded.eventType ?? decoded.type ?? "unknown").lowercased()
        let summary = buildSummary(for: decoded, eventType: eventType)

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: [
                "eventType": eventType,
                "message": decoded.message ?? "",
            ],
            receivedAt: Date()
        )
    }

    private func buildSummary(for payload: Payload, eventType: String) -> String {
        let message = payload.message ?? "Unknown"

        switch eventType {
        case "error", "warning", "info", "success":
            return "[Bazarr] \(message)"
        case "test":
            return "[Bazarr] Test message"
        default:
            return "[Bazarr] Evenement inconnu : \(eventType)"
        }
    }

    private struct Payload: Codable {
        let eventType: String?
        let type: String?
        let message: String?
    }
}

private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
