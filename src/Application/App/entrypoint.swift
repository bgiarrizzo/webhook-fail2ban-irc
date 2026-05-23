import JSONLogger
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
        // Get Server Name
        let serverName: String = Environment.process.SERVER_NAME ?? Sentry.getHostname()

        let sentry: Sentry? =
            sentryDsn.isEmpty
            ? nil
            : try Sentry(
                dsn: sentryDsn,
                servername: serverName,
                release: appVersion,
                environment: envName
            )

        let loggerLevel: Logger.Level = try Logger.Level.detect(from: &environment)

        LoggingSystem.bootstrap { label in
            var logHandlers: [any LogHandler] = []

            // Add Sentry log handler in release builds if SENTRY_DSN is provided
            if let sentry: Sentry = sentry {
                logHandlers.append(
                    ContextualSentryLogHandler(label: label, sentry: sentry, level: .warning)
                )
            }

            // Always add JSON logger handler for structured logs as JSONSeq stream.
            var jsonLogger = JSONLogger.initForJSONSeq(label: label)
            jsonLogger.logLevel = loggerLevel
            logHandlers.append(jsonLogger)

            return MultiplexLogHandler(logHandlers)
        }

        let application: Application = try await Application.make(environment)
        application.logger.notice(
            "Application startup",
            metadata: [
                "environment": "\(envName)",
                "app_version": "\(appVersion)",
                "sentry_enabled": "\(!sentryDsn.isEmpty)",
                "log_level": "\(loggerLevel.rawValue)",
            ]
        )

        // Configure and run the application, ensuring proper shutdown and error handling
        do {
            application.logger.info("Configuring application")
            try await configure(application)
            application.logger.info("Starting application execution loop")
            try await application.execute()
            application.logger.info("Application execution loop completed")
        } catch {
            application.logger.error(
                "Application execution failed",
                metadata: ["error": "\(error)"]
            )
            application.logger.report(error: error)
            try? await application.asyncShutdown()
            try? await sentry?.shutdown()
            throw error
        }

        // Ensure graceful shutdown of application and Sentry when execution completes
        application.logger.info("Shutting down application")
        try await application.asyncShutdown()
        application.logger.info("Shutting down Sentry transport")
        try? await sentry?.shutdown()
    }
}
