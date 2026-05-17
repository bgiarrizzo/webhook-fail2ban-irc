import Foundation

/// Sanitization helpers for safely sending messages to IRC.
public extension String {
    /// Removes IRC control characters and limits output length.
    /// - Parameter maximumLength: Maximum allowed output length.
    /// - Returns: Sanitized IRC-safe text.
    func sanitizedForIRC(maximumLength: Int = 400) -> String {
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
            return sanitized
        }

        return String(sanitized.prefix(maximumLength))
    }
}
