import Foundation
import NIOCore
import NIOEmbedded
import Testing
@testable import webhooks2irc

@Suite("IRCInboundHandler tests")
struct IRCInboundHandlerTests {
	@Test("Forwards complete lines split by CRLF")
	func forwardsCompleteLines() throws {
		let recorder = LineRecorder()
		let handler = IRCInboundHandler { line in
			recorder.append(line)
		}

		let channel = EmbeddedChannel()
		defer { _ = try? channel.finish() }
		try channel.pipeline.addHandler(handler).wait()

		var buffer = channel.allocator.buffer(capacity: 64)
		buffer.writeString("PING :server\r\nNOTICE Auth :ok\r\n")

		_ = try channel.writeInbound(buffer)

		#expect(recorder.snapshot() == ["PING :server", "NOTICE Auth :ok"])
	}

	@Test("Buffers partial lines until CRLF is received")
	func buffersPartialLinesAcrossChunks() throws {
		let recorder = LineRecorder()
		let handler = IRCInboundHandler { line in
			recorder.append(line)
		}

		let channel = EmbeddedChannel()
		defer { _ = try? channel.finish() }
		try channel.pipeline.addHandler(handler).wait()

		var first = channel.allocator.buffer(capacity: 16)
		first.writeString("PING :abc")
		_ = try channel.writeInbound(first)

		#expect(recorder.snapshot().isEmpty)

		var second = channel.allocator.buffer(capacity: 32)
		second.writeString("\r\nPRIVMSG #seedbox :hi\r\nPART")
		_ = try channel.writeInbound(second)

		#expect(recorder.snapshot() == ["PING :abc", "PRIVMSG #seedbox :hi"])
	}

	@Test("Ignores unreadable non UTF-8 chunks")
	func ignoresUnreadableChunks() throws {
		let recorder = LineRecorder()
		let handler = IRCInboundHandler { line in
			recorder.append(line)
		}

		let channel = EmbeddedChannel()
		defer { _ = try? channel.finish() }
		try channel.pipeline.addHandler(handler).wait()

		var invalid = channel.allocator.buffer(capacity: 2)
		invalid.writeBytes([0xFF, 0xFE])
		_ = try channel.writeInbound(invalid)

		#expect(recorder.snapshot().isEmpty)
	}
}

private final class LineRecorder: @unchecked Sendable {
	private let lock = NSLock()
	private var lines: [String] = []

	func append(_ line: String) {
		lock.lock()
		lines.append(line)
		lock.unlock()
	}

	func snapshot() -> [String] {
		lock.lock()
		let copy = lines
		lock.unlock()
		return copy
	}
}
