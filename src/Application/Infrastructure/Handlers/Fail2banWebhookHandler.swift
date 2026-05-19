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

        let bantime: Int = decoded.bantime ?? 0
        let eventType: String = decoded.eventType ?? "unknown"
        let failures: Int = decoded.failures ?? 0
        let hostname: String = decoded.hostname ?? "unknown"
        let ipAddress: String = decoded.ip ?? "unknown"
        let jail: String = decoded.jail ?? "unknown"
        let message: String = decoded.message ?? ""

        // Compose summary based on event type
        let summary: String = {
            switch eventType {
            case "BAN":
                // <hostname> [BAN] - [Jail : <name>] => IP: `<ip>` (https://db-ip.com/<ip>) for <bantime> hours after **<failures>** failure(s).
                return
                    "[Fail2ban] > \(hostname) [\(eventType)] - [Jail : \(jail)] => IP: `\(ipAddress)` (https://db-ip.com/\(ipAddress)) for \(bantime) hours after **\(failures)** failure(s)."
            case "UNBAN":
                // <hostname> [UNBAN] - [Jail : <name>] => IP: <ip> (https://db-ip.com/<ip>)
                return
                    "[Fail2ban] > \(hostname) [\(eventType)] - [Jail : \(jail)] => IP: `\(ipAddress)` (https://db-ip.com/\(ipAddress))"
            case "JAILSTART":
                return "[Fail2ban] > \(hostname) [\(eventType)] - \(jail)"
            case "JAILSTOP":
                return "[Fail2ban] > \(hostname) [\(eventType)] - \(jail)"
            default:
                return message.isEmpty ? "[Fail2ban] Event: \(eventType)" : message
            }
        }()

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: ["ip": ipAddress, "jail": jail],
            receivedAt: Date()
        )
    }

    /// Represents the expected Fail2ban webhook payload.
    private struct Payload: Codable {
        let bantime: Int?
        let eventType: String?
        let failures: Int?
        let hostname: String?
        let ip: String?
        let jail: String?
        let message: String?
    }
}

/// Extracts Data from a ByteBuffer payload.
private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
