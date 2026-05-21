import Foundation
import Logging
import NIOCore
import NIOHTTP1

/// Normalizes Prowlarr webhook payloads into domain events.
public struct ProwlarrWebhookHandler: WebhookHandlerProtocol {
    /// Stable source identifier used by routing and registry.
    public let sourceIdentifier: String = "prowlarr"
    private let logger = Logger(label: "webhooks2irc.handler.prowlarr")

    /// Creates a Prowlarr webhook handler.
    public init() {}

    /// Decodes and normalizes a Prowlarr payload.
    /// - Parameters:
    ///   - payload: Raw request body.
    ///   - headers: HTTP headers.
    /// - Returns: Normalized webhook event.
    public func handle(payload: ByteBuffer, headers: HTTPHeaders) async throws -> WebhookEvent {
        logger.debug(
            "Handling Prowlarr payload",
            metadata: [
                "payload_bytes": "\(payload.readableBytes)",
                "request_id": "\(headers.first(name: "X-Request-Id") ?? "unknown")",
                "content_type": "\(headers.first(name: .contentType) ?? "unknown")",
            ]
        )
        let decoded: Payload

        do {
            let data = try payloadData(from: payload)
            decoded = try JSONDecoder.webhookDecoder().decode(Payload.self, from: data)
        } catch {
            logger.warning("Invalid Prowlarr payload", metadata: ["error": "\(error)"])
            throw WebhookError.invalidPayload("Invalid Prowlarr payload")
        }

        let indexer = decoded.indexer?.name ?? "Unknown"
        let eventType = (decoded.eventType ?? "unknown").lowercased()
        let summary = buildSummary(for: decoded, eventType: eventType)
        logger.info(
            "Prowlarr payload normalized",
            metadata: [
                "event_type": "\(eventType)",
                "indexer": "\(indexer)",
                "summary_length": "\(summary.count)",
            ]
        )

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: [
                "indexerName": indexer,
                "eventType": eventType,
            ],
            receivedAt: Date()
        )
    }

    private func buildSummary(for payload: Payload, eventType: String) -> String {
        let indexer = payload.indexer?.name ?? payload.release?.indexer ?? "Unknown"

        switch eventType {
        case "applicationupdate":
            let previous = payload.previousVersion ?? "Unknown"
            let new = payload.newVersion ?? "Unknown"
            return "[Prowlarr] Mise a jour : \(previous) -> \(new)"
        case "grab":
            let releaseTitle = payload.release?.releaseTitle ?? "Unknown"
            let source = payload.source ?? "Unknown"
            return "[Prowlarr] Grab : \(releaseTitle) depuis \(indexer), demande par \(source)"
        case "health", "healthissue":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Prowlarr] Probleme de sante - \(issueType) : \(message)"
        case "healthrestored":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Prowlarr] Sante restauree - \(issueType) : \(message)"
        case "indexeradded":
            return "[Prowlarr] Indexer ajoute : \(indexer)"
        case "indexererror":
            let message = payload.message ?? "No message"
            return "[Prowlarr] Indexer en erreur : \(indexer) - \(message)"
        case "indexerremoved":
            return "[Prowlarr] Indexer supprime : \(indexer)"
        case "indexerupdated":
            return "[Prowlarr] Indexer mis a jour : \(indexer)"
        case "manualinteractionrequired":
            return "[Prowlarr] Interaction manuelle requise : \(payload.message ?? "No message")"
        case "test":
            return "[Prowlarr] Test message"
        default:
            logger.warning("Unknown Prowlarr event type", metadata: ["event_type": "\(eventType)"])
            return "[Prowlarr] Evenement inconnu : \(eventType)"
        }
    }

    private struct Payload: Codable {
        let eventType: String?
        let indexer: Indexer?
        let release: Release?
        let source: String?
        let type: String?
        let message: String?
        let previousVersion: String?
        let newVersion: String?
    }

    private struct Indexer: Codable {
        let name: String?
    }

    private struct Release: Codable {
        let releaseTitle: String?
        let indexer: String?
    }
}

private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
