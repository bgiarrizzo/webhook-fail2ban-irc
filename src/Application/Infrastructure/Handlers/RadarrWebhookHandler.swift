import Foundation
import Logging
import NIOCore
import NIOHTTP1

/// Normalizes Radarr webhook payloads into domain events.
public struct RadarrWebhookHandler: WebhookHandlerProtocol {
    /// Stable source identifier used by routing and registry.
    public let sourceIdentifier: String = "radarr"
    private let logger = Logger(label: "webhooks2irc.handler.radarr")

    /// Creates a Radarr webhook handler.
    public init() {}

    /// Decodes and normalizes a Radarr payload.
    /// - Parameters:
    ///   - payload: Raw request body.
    ///   - headers: HTTP headers.
    /// - Returns: Normalized webhook event.
    public func handle(payload: ByteBuffer, headers: HTTPHeaders) async throws -> WebhookEvent {
        logger.debug(
            "Handling Radarr payload",
            metadata: [
                "payload_bytes": "\(payload.readableBytes)",
                "request_id": "\(headers.first(name: "X-Request-Id") ?? "unknown")",
                "content_type": "\(headers.first(name: .contentType) ?? "unknown")",
            ])
        let decoded: Payload

        do {
            let data = try payloadData(from: payload)
            decoded = try JSONDecoder.webhookDecoder().decode(Payload.self, from: data)
        } catch {
            logger.warning("Invalid Radarr payload", metadata: ["error": "\(error)"])
            throw WebhookError.invalidPayload("Invalid Radarr payload")
        }

        let title = decoded.movie?.title ?? "Unknown"
        let year = decoded.movie?.year.map(String.init) ?? "Unknown"
        let eventType = (decoded.eventType ?? "unknown").lowercased()
        let summary = buildSummary(for: decoded, eventType: eventType)
        logger.info(
            "Radarr payload normalized",
            metadata: [
                "event_type": "\(eventType)",
                "title": "\(title)",
                "year": "\(year)",
            ])

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: [
                "title": title,
                "year": year,
                "eventType": eventType,
            ],
            receivedAt: Date()
        )
    }

    private func buildSummary(for payload: Payload, eventType: String) -> String {
        let title = payload.movie?.title ?? "Unknown"
        let year = payload.movie?.year.map(String.init) ?? "Unknown"

        switch eventType {
        case "movieadded":
            let tmdbID = payload.movie?.tmdbId.map(String.init) ?? "Unknown"
            let tmdbURL = "https://www.themoviedb.org/movie/\(tmdbID)"
            return "[Radarr] Film ajoute : \(title) (\(year)) - \(tmdbURL)"
        case "moviedelete":
            return "[Radarr] Film supprime : \(title)"
        case "moviedeletedforupgrade":
            let fileName = payload.movieFile?.relativePath ?? "Unknown"
            return "[Radarr] Film supprime pour upgrade : \(title) - \(fileName)"
        case "movieimported":
            let tmdbID = payload.movie?.tmdbId.map(String.init) ?? "Unknown"
            let tmdbURL = "https://www.themoviedb.org/movie/\(tmdbID)"
            return "[Radarr] Film importe : \(title) (\(year)) - \(tmdbURL)"
        case "download":
            let client = payload.downloadClient ?? "Unknown"
            let source = payload.source ?? "Unknown"
            let quality = payload.quality?.quality ?? "Unknown"
            let size = gigabytesString(bytes: payload.size)
            return
                "[Radarr] Telechargement : \(title) via \(client) depuis \(source) - \(quality) - Taille = \(size)"
        case "grab":
            let indexer = payload.release?.indexer ?? "Unknown"
            let releaseTitle = payload.release?.releaseTitle ?? "Unknown"
            let quality = payload.release?.quality ?? "Unknown"
            let size = gigabytesString(bytes: payload.release?.size)
            return
                "[Radarr] Grab : \(title) depuis \(indexer) - ReleaseTitle = \(releaseTitle) - \(quality) - Taille = \(size)"
        case "health":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Radarr] Probleme de sante - \(issueType) : \(message)"
        case "healthrestored":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Radarr] Sante restauree - \(issueType) : \(message)"
        case "manualinteractionrequired":
            return "[Radarr] Interaction manuelle requise : \(payload.message ?? "No message")"
        case "applicationupdate":
            let previous = payload.previousVersion ?? "Unknown"
            let new = payload.newVersion ?? "Unknown"
            return "[Radarr] Mise a jour : \(previous) -> \(new)"
        case "rename":
            return
                "[Radarr] Renomme : \(payload.oldPath ?? "Unknown") -> \(payload.newPath ?? "Unknown")"
        case "upgrade":
            let tmdbID = payload.movie?.tmdbId.map(String.init) ?? "Unknown"
            let tmdbURL = "https://www.themoviedb.org/movie/\(tmdbID)"
            return "[Radarr] Film upgrade : \(title) (\(year)) - \(tmdbURL)"
        case "test":
            return "[Radarr] Test message"
        default:
            logger.warning("Unknown Radarr event type", metadata: ["event_type": "\(eventType)"])
            return "[Radarr] Evenement inconnu : \(eventType)"
        }
    }

    private func gigabytesString(bytes: Int?) -> String {
        guard let bytes else {
            return "Unknown"
        }

        let gb = Double(bytes) / 1024 / 1024 / 1024
        return String(format: "%.2f GB", gb)
    }

    private struct Payload: Codable {
        let eventType: String?
        let movie: Movie?
        let movieFile: MovieFile?
        let downloadClient: String?
        let source: String?
        let quality: Quality?
        let release: Release?
        let size: Int?
        let type: String?
        let message: String?
        let previousVersion: String?
        let newVersion: String?
        let oldPath: String?
        let newPath: String?
    }

    private struct Movie: Codable {
        let title: String?
        let year: Int?
        let tmdbId: Int?
    }

    private struct MovieFile: Codable {
        let relativePath: String?
    }

    private struct Quality: Codable {
        let quality: String?
    }

    private struct Release: Codable {
        let indexer: String?
        let releaseTitle: String?
        let quality: String?
        let size: Int?
    }
}

private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
