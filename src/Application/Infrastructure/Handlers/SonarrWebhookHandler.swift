import Foundation
import Logging
import NIOCore
import NIOHTTP1

/// Normalizes Sonarr webhook payloads into domain events.
public struct SonarrWebhookHandler: WebhookHandlerProtocol {
    /// Stable source identifier used by routing and registry.
    public let sourceIdentifier: String = "sonarr"
    private let logger = Logger(label: "webhooks2irc.handler.sonarr")

    /// Creates a Sonarr webhook handler.
    public init() {}

    /// Decodes and normalizes a Sonarr payload.
    /// - Parameters:
    ///   - payload: Raw request body.
    ///   - headers: HTTP headers.
    /// - Returns: Normalized webhook event.
    public func handle(payload: ByteBuffer, headers: HTTPHeaders) async throws -> WebhookEvent {
        logger.debug(
            "Handling Sonarr payload",
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
            logger.warning("Invalid Sonarr payload", metadata: ["error": "\(error)"])
            throw WebhookError.invalidPayload("Invalid Sonarr payload")
        }

        let series = decoded.series?.title ?? "Unknown"
        let season = decoded.episodes?.first?.seasonNumber ?? 0
        let episode = decoded.episodes?.first?.episodeNumber ?? 0
        let eventType = (decoded.eventType ?? "unknown").lowercased()
        let summary = buildSummary(for: decoded, eventType: eventType)
        logger.info(
            "Sonarr payload normalized",
            metadata: [
                "event_type": "\(eventType)",
                "series": "\(series)",
                "season": "\(season)",
                "episode": "\(episode)",
                "summary_length": "\(summary.count)",
            ]
        )

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: [
                "series": series,
                "season": String(season),
                "episode": String(episode),
                "eventType": eventType,
            ],
            receivedAt: Date()
        )
    }

    private func buildSummary(for payload: Payload, eventType: String) -> String {
        let series = payload.series?.title ?? "Unknown"
        let firstEpisode = payload.episodes?.first
        let season = firstEpisode?.seasonNumber ?? 0
        let episode = firstEpisode?.episodeNumber ?? 0
        let episodeTitle = firstEpisode?.title ?? "Unknown"
        let episodeLabel = episodeLabels(from: payload)

        switch eventType {
        case "episodeadded":
            return "[Sonarr] Episode ajoute : \(series) S\(season)E\(episode) - \(episodeTitle)"
        case "episodedelete":
            return "[Sonarr] Episode supprime : \(series) S\(season)E\(episode) - \(episodeTitle)"
        case "episodedeletedforupgrade":
            let file = payload.episodeFile?.relativePath ?? "Unknown"
            return "[Sonarr] Episode supprime pour upgrade : \(episodeTitle) - \(file)"
        case "episodefiledelete":
            let file = payload.episodeFile?.relativePath ?? "Unknown"
            return
                "[Sonarr] Fichier episode supprime : \(series) S\(season)E\(episode) - \(episodeTitle) - \(file)"
        case "episodeimported":
            return "[Sonarr] Episode importe : \(series) S\(season)E\(episode) - \(episodeTitle)"
        case "download":
            let releaseTitle = payload.release?.releaseTitle ?? "Unknown"
            return "[Sonarr] Episode telecharge : \(series) \(episodeLabel) - \(releaseTitle)"
        case "grab":
            let releaseTitle = payload.release?.releaseTitle ?? "Unknown"
            let quality = payload.release?.quality ?? "Unknown"
            let size = gigabytesString(bytes: payload.release?.size)
            return
                "[Sonarr] Grab : \(episodeLabel) - \(series) - \(releaseTitle) - \(quality) - Taille = \(size)"
        case "health":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Sonarr] Probleme de sante - \(issueType) : \(message)"
        case "healthrestored":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Sonarr] Sante restauree - \(issueType) : \(message)"
        case "manualinteractionrequired":
            return "[Sonarr] Interaction manuelle requise : \(payload.message ?? "No message")"
        case "applicationupdate":
            let previous = payload.previousVersion ?? "Unknown"
            let new = payload.newVersion ?? "Unknown"
            return "[Sonarr] Mise a jour : \(previous) -> \(new)"
        case "seriesdelete":
            return "[Sonarr] Serie supprimee : \(series)"
        case "rename":
            return
                "[Sonarr] Renomme : \(payload.oldPath ?? "Unknown") -> \(payload.newPath ?? "Unknown")"
        case "upgraded":
            return "[Sonarr] Episode upgrade : \(episodeTitle)"
        case "test":
            return "[Sonarr] Test message"
        default:
            logger.warning("Unknown Sonarr event type", metadata: ["event_type": "\(eventType)"])
            return "[Sonarr] Evenement inconnu : \(eventType)"
        }
    }

    private func episodeLabels(from payload: Payload) -> String {
        guard let episodes = payload.episodes, episodes.isEmpty == false else {
            return "S00E00"
        }

        let labels = episodes.map { episode in
            let season = episode.seasonNumber ?? 0
            let number = episode.episodeNumber ?? 0
            return String(format: "S%02dE%02d", season, number)
        }

        return labels.joined(separator: ", ")
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
        let series: Series?
        let episodes: [Episode]?
        let release: Release?
        let message: String?
        let type: String?
        let previousVersion: String?
        let newVersion: String?
        let oldPath: String?
        let newPath: String?
        let episodeFile: EpisodeFile?
    }

    private struct Series: Codable {
        let title: String?
    }

    private struct Episode: Codable {
        let seasonNumber: Int?
        let episodeNumber: Int?
        let title: String?
    }

    private struct Release: Codable {
        let releaseTitle: String?
        let quality: String?
        let size: Int?
    }

    private struct EpisodeFile: Codable {
        let relativePath: String?
    }
}

private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
