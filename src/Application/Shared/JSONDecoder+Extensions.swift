import Foundation

/// Provides shared JSON decoder settings for webhook payload decoding.
public extension JSONDecoder {
    /// Returns a decoder configured for webhook payloads.
    /// - Returns: A configured JSON decoder.
    static func webhookDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
