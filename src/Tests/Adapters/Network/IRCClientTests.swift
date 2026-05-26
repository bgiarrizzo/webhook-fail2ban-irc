import Logging
import NIOCore
import NIOPosix
import Testing
@testable import webhooks2irc

@Suite("IRCClient tests")
struct IRCClientTests {
	@Test("Start throws connectionFailed when server is unreachable")
	func startThrowsConnectionFailedForUnreachableServer() async {
		let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		defer { Task { await shutdown(group) } }

		let client = makeClient(eventLoopGroup: group)

		do {
			try await client.start()
			Issue.record("Expected IRCError.connectionFailed but start succeeded")
		} catch let error as IRCError {
			switch error {
			case .connectionFailed:
				break
			case .disconnected, .sendFailed:
				Issue.record("Expected connectionFailed but got \(error)")
			}
		} catch {
			Issue.record("Expected IRCError but got \(error)")
		}
	}

	@Test("Send throws connectionFailed when disconnected and reconnect fails")
	func sendThrowsConnectionFailedWhenReconnectFails() async {
		let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		defer { Task { await shutdown(group) } }

		let client = makeClient(eventLoopGroup: group)
		let message = IRCMessage(channel: IRCChannel(rawValue: "#seedbox"), text: "hello")

		do {
			try await client.send(message)
			Issue.record("Expected IRCError.connectionFailed but send succeeded")
		} catch let error as IRCError {
			switch error {
			case .connectionFailed:
				break
			case .disconnected, .sendFailed:
				Issue.record("Expected connectionFailed but got \(error)")
			}
		} catch {
			Issue.record("Expected IRCError but got \(error)")
		}
	}

	private func makeClient(eventLoopGroup: any EventLoopGroup) -> IRCClient {
		IRCClient(
			configuration: IRCConnectionConfiguration(
				host: "127.0.0.1",
				port: 1,
				nick: "webhooks-tests",
				password: nil
			),
			channels: [IRCChannel(rawValue: "#seedbox")],
			eventLoopGroup: eventLoopGroup,
			logger: Logger(label: "tests.irc-client")
		)
	}

	private func shutdown(_ group: any EventLoopGroup) async {
		await withCheckedContinuation { continuation in
			group.shutdownGracefully { _ in
				continuation.resume()
			}
		}
	}
}
