import Foundation
import Testing
@testable import webhooks2irc

@Suite("JSONDecoder+Extensions tests")
struct JSONDecoderExtensionsTests {
	@Test("webhookDecoder decodes ISO8601 dates")
	func webhookDecoderDecodesISO8601Dates() throws {
		struct Payload: Decodable {
			let timestamp: Date
		}

		let decoder = JSONDecoder.webhookDecoder()
		let data = Data(#"{"timestamp":"2026-05-26T13:45:12Z"}"#.utf8)
		let expected = ISO8601DateFormatter().date(from: "2026-05-26T13:45:12Z")

		let payload = try decoder.decode(Payload.self, from: data)

		#expect(payload.timestamp == expected)
	}

	@Test("webhookDecoder returns new decoder instances")
	func webhookDecoderReturnsDistinctInstances() {
		let first = JSONDecoder.webhookDecoder()
		let second = JSONDecoder.webhookDecoder()

		#expect(first !== second)
	}

	@Test("webhookDecoder rejects non ISO8601 date strings")
	func webhookDecoderRejectsNonISO8601Dates() {
		struct Payload: Decodable {
			let timestamp: Date
		}

		let decoder = JSONDecoder.webhookDecoder()
		let invalidData = Data(#"{"timestamp":"26/05/2026 13:45:12"}"#.utf8)

		#expect(throws: DecodingError.self) {
			_ = try decoder.decode(Payload.self, from: invalidData)
		}
	}
}
