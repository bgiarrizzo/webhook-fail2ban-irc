import Logging
import NIOCore
import NIOPosix
import SwiftSentry
import Vapor

@main
enum Entrypoint {
    static func main() async throws {
        var environment: Environment = try Environment.detect()

        // From environment variables
        // Get Env name
        let envName: String = Environment.process.ENV_NAME ?? "unknown"
        // Get App Version
        let appVersion: String = Environment.process.APP_VERSION ?? "unknown"
        // Get Sentry DSN
        let sentryDsn: String = Environment.process.SENTRY_DSN ?? ""

        let sentry: Sentry? =
            sentryDsn.isEmpty
            ? nil : try Sentry(dsn: sentryDsn, release: appVersion, environment: envName)

        let loggerLevel: Logger.Level = try Logger.Level.detect(from: &environment)

        LoggingSystem.bootstrap { label in
            var logHandlers: [any LogHandler] = []

            // Add Sentry log handler in release builds if SENTRY_DSN is provided
            if let sentry: Sentry = sentry {
                logHandlers.append(SentryLogHandler(label: label, sentry: sentry, level: .warning))
            }

            // Always add console log handler for local development and visibility
            let console: Terminal = Terminal()
            logHandlers.append(ConsoleLogger(label: label, console: console, level: loggerLevel))

            return MultiplexLogHandler(logHandlers)
        }

        let application: Application = try await Application.make(environment)

        // Configure and run the application, ensuring proper shutdown and error handling
        do {
            try await configure(application)
            try await application.execute()
        } catch {
            application.logger.report(error: error)
            try? await application.asyncShutdown()
            try? await sentry?.shutdown()
            throw error
        }

        // Ensure graceful shutdown of application and Sentry when execution completes
        try await application.asyncShutdown()
        try? await sentry?.shutdown()
    }
}
