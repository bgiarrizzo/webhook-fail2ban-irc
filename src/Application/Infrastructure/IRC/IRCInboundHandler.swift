import Logging
import NIOCore

/// Receives IRC server lines and forwards them to the client orchestration logic.
public final class IRCInboundHandler: ChannelInboundHandler, @unchecked Sendable {
    public typealias InboundIn = ByteBuffer

    private var carry: String
    private let onLine: @Sendable (String) -> Void
    private let logger = Logger(label: "webhooks2irc.infrastructure.irc-inbound")

    /// Creates an inbound IRC line handler.
    /// - Parameter onLine: Callback invoked for each complete IRC line.
    public init(onLine: @escaping @Sendable (String) -> Void) {
        self.carry = ""
        self.onLine = onLine
        logger.debug("IRC inbound handler initialized")
    }

    /// Handles incoming bytes from the IRC server.
    /// - Parameters:
    ///   - context: Channel context.
    ///   - data: Incoming data.
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        guard let chunk = buffer.readString(length: buffer.readableBytes) else {
            logger.warning("Received unreadable IRC chunk")
            return
        }

        logger.debug("Received IRC chunk", metadata: ["chunk_bytes": "\(chunk.utf8.count)"])

        carry += chunk

        while let range = carry.range(of: "\r\n") {
            let line = String(carry[..<range.lowerBound])
            carry = String(carry[range.upperBound...])
            logger.debug("Forwarding IRC line", metadata: ["line_length": "\(line.count)"])
            onLine(line)
        }

        if carry.isEmpty == false {
            logger.debug("Partial IRC line buffered", metadata: ["carry_length": "\(carry.count)"])
        }
    }
}
