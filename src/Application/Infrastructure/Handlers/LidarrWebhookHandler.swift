import Foundation
import Logging
import NIOCore
import NIOHTTP1

/// Normalizes Lidarr webhook payloads into domain events.
public struct LidarrWebhookHandler: WebhookHandlerProtocol {
    /// Stable source identifier used by routing and registry.
    public let sourceIdentifier: String = "lidarr"
    private let logger = Logger(label: "webhooks2irc.handler.lidarr")

    /// Creates a Lidarr webhook handler.
    public init() {}

    /// Decodes and normalizes a Lidarr payload.
    /// - Parameters:
    ///   - payload: Raw request body.
    ///   - headers: HTTP headers.
    /// - Returns: Normalized webhook event.
    public func handle(payload: ByteBuffer, headers: HTTPHeaders) async throws -> WebhookEvent {
        logger.debug(
            "Handling Lidarr payload",
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
            logger.warning("Invalid Lidarr payload", metadata: ["error": "\(error)"])
            throw WebhookError.invalidPayload("Invalid Lidarr payload")
        }

        let artist = decoded.artist?.name ?? "Unknown"
        let album = decoded.album?.title ?? "Unknown"
        let eventType = (decoded.eventType ?? "unknown").lowercased()
        let summary = buildSummary(for: decoded, eventType: eventType)
        logger.info(
            "Lidarr payload normalized",
            metadata: [
                "event_type": "\(eventType)",
                "artist": "\(artist)",
                "album": "\(album)",
                "summary_length": "\(summary.count)",
            ]
        )

        return WebhookEvent(
            source: sourceIdentifier,
            eventType: eventType,
            summary: summary,
            metadata: [
                "artist": artist,
                "album": album,
                "eventType": eventType,
            ],
            receivedAt: Date()
        )
    }

    private func buildSummary(for payload: Payload, eventType: String) -> String {
        let artist = payload.artist?.name ?? "Unknown"
        let album = payload.album?.title ?? "Unknown"
        let year = payload.album?.year.map(String.init) ?? "Unknown"

        switch eventType {
        case "albumadded":
            if let albums = payload.albums, albums.isEmpty == false {
                let titles = albums.compactMap { $0.title }
                let joined = titles.isEmpty ? album : titles.joined(separator: " & ")
                return "[Lidarr] Album ajoute : \(joined) - \(artist) (\(year))"
            }
            return "[Lidarr] Album ajoute : \(artist) - \(album)"
        case "albumdelete":
            return "[Lidarr] Album supprime : \(artist) - \(album) (\(year))"
        case "albumdeletedforupgrade":
            let file = payload.albumFile?.relativePath ?? "Unknown"
            return "[Lidarr] Album supprime pour upgrade : \(album) - \(artist) - \(file)"
        case "albumimported":
            return "[Lidarr] Album importe : \(artist) - \(album) (\(year))"
        case "applicationupdate":
            let previous = payload.previousVersion ?? "Unknown"
            let new = payload.newVersion ?? "Unknown"
            return "[Lidarr] Mise a jour : \(previous) -> \(new)"
        case "artistadd":
            return "[Lidarr] Artiste ajoute : \(artist)"
        case "artistdelete":
            return "[Lidarr] Artiste supprime : \(artist)"
        case "download":
            let title = resolveAlbumTitles(from: payload)
            return "[Lidarr] Telechargement : \(title) - \(artist)"
        case "grab":
            let releaseTitle = payload.release?.releaseTitle ?? "Unknown"
            let quality = payload.release?.quality ?? "Unknown"
            let size = gigabytesString(bytes: payload.release?.size)
            let title = resolveAlbumTitles(from: payload)
            return
                "[Lidarr] Grab : \(title) - \(artist) - ReleaseTitle = \(releaseTitle) - \(quality) - Taille = \(size)"
        case "health", "healthissue":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Lidarr] Probleme de sante - \(issueType) : \(message)"
        case "healthrestored":
            let issueType = payload.type ?? "Unknown"
            let message = payload.message ?? "No message"
            return "[Lidarr] Sante restauree - \(issueType) : \(message)"
        case "importfailure":
            return "[Lidarr] Echec import"
        case "manualinteractionrequired":
            return "[Lidarr] Interaction manuelle requise : \(payload.message ?? "No message")"
        case "rename":
            return
                "[Lidarr] Renomme : \(payload.oldPath ?? "Unknown") -> \(payload.newPath ?? "Unknown")"
        case "retag":
            return "[Lidarr] Retag : \(payload.trackFile?.path ?? "Unknown")"
        case "upgraded":
            return "[Lidarr] Upgrade : \(artist) - \(album)"
        case "test":
            return "[Lidarr] Test message"
        default:
            logger.warning("Unknown Lidarr event type", metadata: ["event_type": "\(eventType)"])
            return "[Lidarr] Evenement inconnu : \(eventType)"
        }
    }

    private func resolveAlbumTitles(from payload: Payload) -> String {
        if let albums = payload.albums, albums.isEmpty == false {
            let titles = albums.compactMap { $0.title }
            if titles.isEmpty == false {
                return titles.joined(separator: " & ")
            }
        }

        return payload.album?.title ?? "Unknown"
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
        let artist: Artist?
        let album: Album?
        let albums: [Album]?
        let albumFile: AlbumFile?
        let release: Release?
        let type: String?
        let message: String?
        let previousVersion: String?
        let newVersion: String?
        let oldPath: String?
        let newPath: String?
        let trackFile: TrackFile?
    }

    private struct Artist: Codable {
        let name: String?
    }

    private struct Album: Codable {
        let title: String?
        let year: Int?
    }

    private struct AlbumFile: Codable {
        let relativePath: String?
    }

    private struct Release: Codable {
        let releaseTitle: String?
        let quality: String?
        let size: Int?
    }

    private struct TrackFile: Codable {
        let path: String?
    }
}

private func payloadData(from payload: ByteBuffer) throws -> Data {
    var mutable = payload

    guard let bytes = mutable.readBytes(length: mutable.readableBytes) else {
        throw WebhookError.invalidPayload("Empty payload")
    }

    return Data(bytes)
}
