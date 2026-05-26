import Foundation
import Logging

private let jsonDecoderLogger = Logger(label: "webhooks2irc.shared.json-decoder")

/// Provides shared JSON decoder settings for webhook payload decoding.
public extension JSONDecoder {
    /// Returns a decoder configured for webhook payloads.
    /// - Returns: A configured JSON decoder.
    static func webhookDecoder() -> JSONDecoder {
        jsonDecoderLogger.debug("Creating webhook JSON decoder")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
