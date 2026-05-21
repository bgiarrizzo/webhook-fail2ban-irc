import Foundation
import Logging
import SwiftSentry

/// Stores recent log records so warning and error events can carry execution breadcrumbs.
final class BreadcrumbTrailStore: @unchecked Sendable {
    /// One breadcrumb record captured from the logging pipeline.
    struct Entry: Sendable {
        /// Timestamp recorded when the log entry was emitted.
        let timestamp: Date

        /// Severity of the recorded log message.
        let level: Logger.Level

        /// Logger label that emitted the message.
        let label: String

        /// Human-readable log message.
        let message: String

        /// Associated metadata at emission time.
        let metadata: Logger.Metadata
    }

    private let lock = NSLock()
    private let capacity: Int
    private var entries: [Entry]
    private let formatter: ISO8601DateFormatter

    /// Creates a bounded breadcrumb store.
    /// - Parameter capacity: Maximum number of entries preserved in memory.
    init(capacity: Int = 200) {
        self.capacity = capacity
        self.entries = []
        self.formatter = ISO8601DateFormatter()
        self.formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    /// Appends one breadcrumb entry to the in-memory ring buffer.
    /// - Parameters:
    ///   - level: Log level.
    ///   - label: Logger label.
    ///   - message: Log message.
    ///   - metadata: Log metadata.
    func record(level: Logger.Level, label: String, message: String, metadata: Logger.Metadata) {
        let filteredMetadata = metadata.filter { key, _ in
            key.hasPrefix("breadcrumb_") == false && key != "breadcrumbs_scope"
        }

        lock.lock()
        defer { lock.unlock() }

        entries.append(
            Entry(
                timestamp: Date(),
                level: level,
                label: label,
                message: message,
                metadata: filteredMetadata
            ))

        if entries.count > capacity {
            entries.removeFirst(entries.count - capacity)
        }
    }

    /// Builds metadata describing recent breadcrumbs for the given event context.
    /// - Parameters:
    ///   - metadata: Current event metadata.
    ///   - limit: Maximum number of breadcrumbs attached to the event.
    /// - Returns: Metadata entries ready to be merged into a log event.
    func metadataForEvent(metadata: Logger.Metadata, limit: Int) -> Logger.Metadata {
        let requestID = metadata["request_id"]?.description

        lock.lock()
        let snapshot = entries
        lock.unlock()

        let scopedEntries: [Entry]
        let scope: String

        if let requestID, requestID.isEmpty == false {
            let matchingEntries = snapshot.filter { entry in
                entry.metadata["request_id"]?.description == requestID
            }

            if matchingEntries.isEmpty == false {
                scopedEntries = matchingEntries
                scope = "request_id"
            } else {
                scopedEntries = snapshot
                scope = "global-fallback"
            }
        } else {
            scopedEntries = snapshot
            scope = "global"
        }

        let recentEntries = Array(scopedEntries.suffix(limit))
        var breadcrumbMetadata: Logger.Metadata = [
            "breadcrumbs_scope": .string(scope),
            "breadcrumb_count": .stringConvertible(recentEntries.count),
        ]

        for (index, entry) in recentEntries.enumerated() {
            let key = "breadcrumb_\(index + 1)"
            breadcrumbMetadata[key] = .string(compactDescription(for: entry))
        }

        return breadcrumbMetadata
    }

    private func compactDescription(for entry: Entry) -> String {
        let timestamp = formatter.string(from: entry.timestamp)
        let compactMetadata = entry.metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ",")
        let combined =
            compactMetadata.isEmpty
            ? "\(timestamp) | \(entry.level.rawValue) | \(entry.label) | \(entry.message)"
            : "\(timestamp) | \(entry.level.rawValue) | \(entry.label) | \(entry.message) | \(compactMetadata)"

        if combined.count <= 180 {
            return combined
        }

        return String(combined.prefix(177)) + "..."
    }
}

/// Wraps SwiftSentry's log handler and enriches warning/error events with recent breadcrumbs.
struct ContextualSentryLogHandler: LogHandler {
    private static let breadcrumbStore = BreadcrumbTrailStore()

    private let label: String
    private let sentry: Sentry
    private let breadcrumbLimit: Int
    private var baseMetadata: Logger.Metadata

    /// Minimum log level forwarded to the wrapped Sentry handler.
    var logLevel: Logger.Level

    /// Optional metadata provider used by SwiftLog.
    var metadataProvider: Logger.MetadataProvider?

    /// Accesses handler metadata.
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            baseMetadata[metadataKey]
        }
        set {
            baseMetadata[metadataKey] = newValue
        }
    }

    /// Full metadata attached to the handler.
    var metadata: Logger.Metadata {
        get {
            baseMetadata
        }
        set {
            baseMetadata = newValue
        }
    }

    /// Creates a contextual Sentry handler.
    /// - Parameters:
    ///   - label: Logger label.
    ///   - sentry: Sentry instance.
    ///   - level: Minimum level to send to Sentry.
    ///   - breadcrumbLimit: Maximum breadcrumb entries attached to one event.
    init(label: String, sentry: Sentry, level: Logger.Level, breadcrumbLimit: Int = 6) {
        self.label = label
        self.sentry = sentry
        self.breadcrumbLimit = breadcrumbLimit
        self.baseMetadata = [:]
        self.logLevel = level
        self.metadataProvider = nil
    }

    /// Records one log line and forwards warning/error events to Sentry with breadcrumb metadata.
    /// - Parameters:
    ///   - level: Log level.
    ///   - message: Log message.
    ///   - metadata: Inline metadata.
    ///   - source: Log source.
    ///   - file: Source file.
    ///   - function: Source function.
    ///   - line: Source line.
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let mergedMetadata = (metadata ?? [:])
            .merging(baseMetadata, uniquingKeysWith: { current, _ in current })
            .merging(metadataProvider?.get() ?? [:], uniquingKeysWith: { current, _ in current })

        let breadcrumbMetadata =
            level >= .warning
            ? Self.breadcrumbStore.metadataForEvent(
                metadata: mergedMetadata, limit: breadcrumbLimit)
            : [:]
        let enrichedMetadata = mergedMetadata.merging(
            breadcrumbMetadata, uniquingKeysWith: { current, _ in current })
        let normalizedMetadata = Self.normalizeMetadataForSentry(enrichedMetadata)

        Self.breadcrumbStore.record(
            level: level,
            label: label,
            message: message.description,
            metadata: mergedMetadata
        )

        var handler = SentryLogHandler(label: label, sentry: sentry, level: logLevel)
        handler.log(
            level: level,
            message: message,
            metadata: normalizedMetadata,
            source: source,
            file: file,
            function: function,
            line: line
        )
    }

    /// Converts metadata keys to Sentry-friendly tags using a consistent ctx_ prefix.
    /// - Parameter metadata: Metadata to normalize.
    /// - Returns: Metadata with normalized keys ready for Sentry ingestion.
    static func normalizeMetadataForSentry(_ metadata: Logger.Metadata) -> Logger.Metadata {
        var normalized: Logger.Metadata = [:]

        for (key, value) in metadata {
            normalized[normalizedMetadataKey(key)] = value
        }

        return normalized
    }

    /// Converts one metadata key into a normalized Sentry tag key.
    /// - Parameter key: Original metadata key.
    /// - Returns: Normalized key prefixed with ctx_.
    static func normalizedMetadataKey(_ key: String) -> String {
        let lowercased = key.lowercased()
        let sanitized = lowercased.map { char in
            if char.isLetter || char.isNumber || char == "_" {
                return char
            }
            return "_"
        }

        let normalized = String(sanitized)
        if normalized.hasPrefix("ctx_") {
            return normalized
        }

        return "ctx_\(normalized)"
    }
}
