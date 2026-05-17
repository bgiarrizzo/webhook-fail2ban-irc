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

        for channel in channels {
            try await sendRaw("JOIN \(channel.rawValue)")
        }
    }

    private func sendRaw(_ line: String) async throws {
        guard let channel = activeChannel else {
            throw IRCError.disconnected
        }

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
        if line.hasPrefix("PING") {
            let token = line.dropFirst(4).trimmingCharacters(in: .whitespaces)
            let response = token.isEmpty ? "PONG" : "PONG \(token)"
            try? await sendRaw(response)
        }
    }

    private func handleDisconnect() async {
        activeChannel = nil
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
