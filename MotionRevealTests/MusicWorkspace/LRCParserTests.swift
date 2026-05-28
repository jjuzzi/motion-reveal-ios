import XCTest
@testable import MotionReveal

final class LRCParserTests: XCTestCase {
    func testParsesTimedLinesAndAddsEndTimes() throws {
        let text = """
        [00:01.00]First line
        [00:03.50]Second line
        """

        let lines = try LRCParser().parse(text)

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].startTime, 1.0, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(lines[0].endTime), 3.5, accuracy: 0.001)
        XCTAssertEqual(lines[1].text, "Second line")
        XCTAssertNil(lines[1].endTime)
    }

    func testParsesMultipleTimestampsOnOneLine() throws {
        let text = "[00:01.00][00:04.25]Hook"

        let lines = try LRCParser().parse(text)

        XCTAssertEqual(lines.map(\.text), ["Hook", "Hook"])
        XCTAssertEqual(lines.map(\.startTime), [1.0, 4.25])
        XCTAssertEqual(try XCTUnwrap(lines[0].endTime), 4.25, accuracy: 0.001)
    }

    func testIgnoresMetadataAndUntimedLines() throws {
        let text = """
        [ar:Artist]
        topline draft
        [00:02.00]First timed idea
        """

        let lines = try LRCParser().parse(text)

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].text, "First timed idea")
    }

    func testThrowsUsefulErrorForInvalidTimestamp() {
        XCTAssertThrowsError(try LRCParser().parse("[00:bad]Broken")) { error in
            XCTAssertEqual(error as? LyricParseError, .invalidTimestamp("00:bad"))
        }
    }

    func testRejectsNegativeAndOutOfRangeTimestamps() {
        XCTAssertThrowsError(try LRCParser().parse("[-01:00.00]Backwards")) { error in
            XCTAssertEqual(error as? LyricParseError, .invalidTimestamp("-01:00.00"))
        }

        XCTAssertThrowsError(try LRCParser().parse("[00:60.00]Invalid seconds")) { error in
            XCTAssertEqual(error as? LyricParseError, .invalidTimestamp("00:60.00"))
        }
    }

    func testRejectsOversizedLyricInput() {
        let oversized = String(repeating: "x", count: LRCParser.maximumInputBytes + 1)

        XCTAssertThrowsError(try LRCParser().parse(oversized)) { error in
            XCTAssertEqual(error as? LyricParseError, .inputTooLarge)
        }
    }

    func testRejectsTooManyTimestampsOnOneLine() {
        let timestamps = (0...LRCParser.maximumTimestampsPerLine)
            .map { value in
                let seconds = value < 10 ? "0\(value)" : "\(value)"
                return "[00:\(seconds).00]"
            }
            .joined()

        XCTAssertThrowsError(try LRCParser().parse("\(timestamps)Hook")) { error in
            XCTAssertEqual(error as? LyricParseError, .tooManyTimestamps(line: 1))
        }
    }

    func testActiveLineUsesStableLineIdentity() throws {
        let lines = try LRCParser().parse(
            """
            [00:01.00]First
            [00:03.00]Second
            """
        )

        XCTAssertEqual(lines.activeLineID(at: 2), lines[0].id)
        XCTAssertEqual(lines.activeLineID(at: 3), lines[1].id)
        XCTAssertNil(lines.activeLineID(at: 0.5))
    }

    func testParserIDsAreStableAcrossReparses() throws {
        let text = """
        [00:01.00]First
        [00:03.00]Second
        """

        let firstParse = try LRCParser().parse(text)
        let secondParse = try LRCParser().parse(text)

        XCTAssertEqual(firstParse.map(\.id), secondParse.map(\.id))
    }

    func testSameTimestampLinesPreserveSourceOrder() throws {
        let lines = try LRCParser().parse(
            """
            [00:02.00]Beta
            [00:02.00]Alpha
            [00:03.00]Next
            """
        )

        XCTAssertEqual(lines.map(\.text), ["Beta", "Alpha", "Next"])
        XCTAssertEqual(lines.activeLineID(at: 2), lines[1].id)
    }

    func testSongTextDocumentParsesTimedLyrics() throws {
        let document = SongTextDocument(kind: .lyrics, text: "[00:07.00]Punch line")

        let lines = try document.parsedTimedLyrics()

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].startTime, 7, accuracy: 0.001)
    }
}
