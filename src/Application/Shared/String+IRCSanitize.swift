import Foundation
import Logging

private let ircSanitizeLogger = Logger(label: "webhooks2irc.shared.irc-sanitize")

/// Sanitization helpers for safely sending messages to IRC.
extension String {
    /// Removes IRC control characters and limits output length.
    /// - Parameter maximumLength: Maximum allowed output length.
    /// - Returns: Sanitized IRC-safe text.
    public func sanitizedForIRC(maximumLength: Int = 400) -> String {
        let originalLength = count
        let filteredScalars = unicodeScalars.filter { scalar in
            if scalar.value == 10 || scalar.value == 13 {
                return false
            }

            if scalar.value < 32 || scalar.value == 127 {
                return false
            }

            return true
        }

        let sanitized = String(String.UnicodeScalarView(filteredScalars))

        if sanitized.count <= maximumLength {
            if sanitized.count != originalLength {
                ircSanitizeLogger.debug(
                    "IRC message sanitized",
                    metadata: [
                        "original_length": "\(originalLength)",
                        "sanitized_length": "\(sanitized.count)",
                        "truncated": "false",
                    ])
            }
            return sanitized
        }

        ircSanitizeLogger.debug(
            "IRC message sanitized and truncated",
            metadata: [
                "original_length": "\(originalLength)",
                "sanitized_length": "\(sanitized.count)",
                "maximum_length": "\(maximumLength)",
            ])
        return String(sanitized.prefix(maximumLength))
    }
}
