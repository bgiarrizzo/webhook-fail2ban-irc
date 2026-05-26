import Testing
@testable import webhooks2irc

@Suite("String+IRCSanitize tests")
struct StringIRCSanitizeTests {
	@Test("Removes CR, LF, C0 controls, and DEL")
	func removesControlCharacters() {
		let value = "Hello\r\nWorld\u{0001}\u{0009}\u{007F}!"

		let sanitized = value.sanitizedForIRC()

		#expect(sanitized == "HelloWorld!")
	}

	@Test("Preserves printable and Unicode characters")
	func preservesPrintableAndUnicode() {
		let value = "Status: all good 🤖 café"

		let sanitized = value.sanitizedForIRC()

		#expect(sanitized == value)
	}

	@Test("Truncates after sanitization to maximum length")
	func truncatesToProvidedMaximumLength() {
		let value = "AB\r\n" + String(repeating: "x", count: 10)

		let sanitized = value.sanitizedForIRC(maximumLength: 5)

		#expect(sanitized == "ABxxx")
		#expect(sanitized.count == 5)
	}

	@Test("Uses default maximum length of 400")
	func usesDefaultMaximumLength() {
		let value = String(repeating: "x", count: 500)

		let sanitized = value.sanitizedForIRC()

		#expect(sanitized.count == 400)
	}
}
