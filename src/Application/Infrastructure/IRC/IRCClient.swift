import Foundation
import Logging
import NIOCore
import NIOPosix

/// NIO-based IRC client with persistent TCP lifecycle and in-memory buffering.
public actor IRCClient: IRCClientProtocol {
    private let configuration: IRCConnectionConfiguration
    private let channels: [IRCChannel]
    private let eventLoopGroup: any EventLoopGroup
    private let logger: Logger

    private var activeChannel: (any Channel)?
    private var isConnecting: Bool
    private var pendingMessages: [IRCMessage]
    private var isRegistered: Bool = false

    /// Creates an IRC client.
    /// - Parameters:
    ///   - configuration: Connection configuration.
    ///   - channels: Channels to join at startup.
    ///   - eventLoopGroup: Shared event loop group.
    ///   - logger: Logger instance.
    public init(
        configuration: IRCConnectionConfiguration,
        channels: Set<IRCChannel>,
        eventLoopGroup: any EventLoopGroup,
        logger: Logger
    ) {
        self.configuration = configuration
        self.channels = channels.sorted { $0.rawValue < $1.rawValue }
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
        self.activeChannel = nil
        self.isConnecting = false
        self.pendingMessages = []
    }

    /// Starts the IRC client lifecycle.
    public func start() async throws {
        try await connectIfNeeded()
    }

    /// Sends one message to IRC or queues it when disconnected.
    /// - Parameter message: Message to relay.
    public func send(_ message: IRCMessage) async throws {
        if activeChannel == nil {
            pendingMessages.append(message)
            try await connectIfNeeded()
            return
        }

        do {
            try await sendRaw("PRIVMSG \(message.channel.rawValue) :\(message.text)")
        } catch {
            logger.error(
                "IRC send failed, queueing message and reconnecting",
                metadata: ["error": "\(error)"])
            pendingMessages.append(message)
            activeChannel = nil
            try await scheduleReconnect()
        }
    }

    private func connectIfNeeded() async throws {
        if activeChannel != nil || isConnecting {
            return
        }

        isConnecting = true

        let bootstrap = ClientBootstrap(group: eventLoopGroup)
            .channelInitializer { channel in
                channel.pipeline.addHandler(
                    IRCInboundHandler(onLine: { line in
                        Task {
                            await self.handleInboundLine(line)
                        }
                    }))
            }

        do {
            let channel = try await bootstrap.connect(
                host: configuration.host, port: configuration.port
            ).get()
            activeChannel = channel
            isConnecting = false

            channel.closeFuture.whenComplete { _ in
                Task {
                    await self.handleDisconnect()
                }
            }

            try await performHandshake()
            try await flushPendingMessages()
        } catch {
            isConnecting = false
            logger.error("IRC connection failed", metadata: ["error": "\(error)"])
            throw IRCError.connectionFailed(String(describing: error))
        }
    }

    private func performHandshake() async throws {
        if let password = configuration.password, password.isEmpty == false {
            try await sendRaw("PASS \(password)")
        }

        try await sendRaw("NICK \(configuration.nick)")
        try await sendRaw("USER \(configuration.nick) 0 * :webhook-irc-relay")

        logger.info("Waiting for server registration (001 RPL_WELCOME)...")
        // JOIN commands will be sent after receiving 001 RPL_WELCOME
    }

    private func joinChannelsAndAnnounce() async throws {
        logger.info("Server registered, joining \(channels.count) channels...")

        for channel in channels {
            try await sendRaw("JOIN \(channel.rawValue)")
        }

        // Wait for server to process JOINs before announcing presence
        logger.info("Waiting for JOIN confirmations before announcing presence...")
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

        logger.info("Announcing presence in \(channels.count) channels")
        try await announcePresence()
    }

    private func announcePresence() async throws {
        let announcement = "🤖 Bot is up & running!"
        logger.info(
            "Sending presence announcement to channels",
            metadata: ["channels": "\(channels.map { $0.rawValue }.joined(separator: ", "))"])

        for channel in channels {
            do {
                try await sendRaw("PRIVMSG \(channel.rawValue) :\(announcement)")
                logger.info("Presence announced", metadata: ["channel": "\(channel.rawValue)"])
            } catch {
                logger.error(
                    "Failed to announce presence",
                    metadata: ["channel": "\(channel.rawValue)", "error": "\(error)"])
            }
        }
    }

    private func sendRaw(_ line: String) async throws {
        guard let channel = activeChannel else {
            throw IRCError.disconnected
        }

        logger.debug("IRC >> \(line)")

        var buffer = channel.allocator.buffer(capacity: line.utf8.count + 2)
        buffer.writeString(line)
        buffer.writeString("\r\n")

        do {
            try await channel.writeAndFlush(buffer).get()
        } catch {
            throw IRCError.sendFailed(String(describing: error))
        }
    }

    private func handleInboundLine(_ line: String) async {
        logger.debug("IRC << \(line)")

        // Handle PING
        if line.hasPrefix("PING") {
            let token = line.dropFirst(4).trimmingCharacters(in: .whitespaces)
            let response = token.isEmpty ? "PONG" : "PONG \(token)"
            try? await sendRaw(response)
            return
        }

        // Handle 001 RPL_WELCOME - server accepted our registration
        if !isRegistered && line.contains(" 001 ") {
            logger.info("Received RPL_WELCOME (001), registration complete")
            isRegistered = true
            try? await joinChannelsAndAnnounce()
        }
    }

    private func handleDisconnect() async {
        activeChannel = nil
        isRegistered = false
        if isConnecting {
            return
        }

        try? await scheduleReconnect()
    }

    private func scheduleReconnect() async throws {
        try await Task.sleep(nanoseconds: 2_000_000_000)
        try await connectIfNeeded()
    }

    private func flushPendingMessages() async throws {
        guard pendingMessages.isEmpty == false else {
            return
        }

        let buffered = pendingMessages
        pendingMessages.removeAll(keepingCapacity: true)

        for message in buffered {
            try await send(message)
        }
    }
}
