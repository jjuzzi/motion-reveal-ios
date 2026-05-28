import Foundation

struct TimedLyricLine: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var startTime: TimeInterval
    var endTime: TimeInterval?
    var text: String

    init(
        id: String,
        startTime: TimeInterval,
        endTime: TimeInterval? = nil,
        text: String
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func contains(_ playbackTime: TimeInterval) -> Bool {
        guard playbackTime >= startTime else { return false }
        guard let endTime else { return true }
        return playbackTime < endTime
    }
}

enum LyricParseError: Error, Equatable, LocalizedError {
    case emptyInput
    case inputTooLarge
    case tooManyLines
    case tooManyTimestamps(line: Int)
    case tooManyTimedLines
    case noTimedLines
    case invalidTimestamp(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "The lyric file is empty."
        case .inputTooLarge:
            return "The lyric file is too large."
        case .tooManyLines:
            return "The lyric file has too many lines."
        case let .tooManyTimestamps(line):
            return "Too many timestamps on lyric line \(line)."
        case .tooManyTimedLines:
            return "The lyric file has too many timed lines."
        case .noTimedLines:
            return "No timestamped lyric lines were found."
        case let .invalidTimestamp(value):
            return "Invalid lyric timestamp: \(value)"
        }
    }
}

struct LRCParser: Sendable {
    static let maximumInputBytes = 512 * 1024
    static let maximumLineCount = 10_000
    static let maximumTimedLineCount = 20_000
    static let maximumTimestampsPerLine = 12
    static let maximumTimestampSeconds: TimeInterval = 24 * 60 * 60

    func parse(_ text: String) throws -> [TimedLyricLine] {
        guard text.utf8.count <= Self.maximumInputBytes else {
            throw LyricParseError.inputTooLarge
        }

        let rawLines = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)

        guard !rawLines.isEmpty else {
            throw LyricParseError.emptyInput
        }

        guard rawLines.count <= Self.maximumLineCount else {
            throw LyricParseError.tooManyLines
        }

        var parsed: [ParsedTimedLyricLine] = []
        for (sourceLineIndex, line) in rawLines.enumerated() {
            parsed.append(contentsOf: try parseLine(line, sourceLineIndex: sourceLineIndex))
            guard parsed.count <= Self.maximumTimedLineCount else {
                throw LyricParseError.tooManyTimedLines
            }
        }

        parsed.sort { lhs, rhs in
            if lhs.lyricLine.startTime == rhs.lyricLine.startTime {
                if lhs.sourceLineIndex == rhs.sourceLineIndex {
                    return lhs.timestampOffset < rhs.timestampOffset
                }
                return lhs.sourceLineIndex < rhs.sourceLineIndex
            }
            return lhs.lyricLine.startTime < rhs.lyricLine.startTime
        }

        guard !parsed.isEmpty else {
            throw LyricParseError.noTimedLines
        }

        return parsed.enumerated().map { index, line in
            var line = line.lyricLine
            if index + 1 < parsed.count {
                line.endTime = parsed[index + 1].lyricLine.startTime
            }
            return line
        }
    }

    private func parseLine(_ line: String, sourceLineIndex: Int) throws -> [ParsedTimedLyricLine] {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("[") else { return [] }

        var remaining = trimmed[...]
        var timestamps: [(offset: Int, time: TimeInterval)] = []

        while remaining.first == "[" {
            guard let closeIndex = remaining.firstIndex(of: "]") else { return [] }
            let rawStamp = String(remaining[remaining.index(after: remaining.startIndex)..<closeIndex])
            guard isLyricTimestamp(rawStamp) else { return [] }

            guard timestamps.count < Self.maximumTimestampsPerLine else {
                throw LyricParseError.tooManyTimestamps(line: sourceLineIndex + 1)
            }

            timestamps.append((timestamps.count, try parseTimestamp(rawStamp)))
            remaining = remaining[remaining.index(after: closeIndex)...]
        }

        let lyricText = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !timestamps.isEmpty, !lyricText.isEmpty else { return [] }

        return timestamps.map { timestamp in
            ParsedTimedLyricLine(
                lyricLine: TimedLyricLine(
                    id: stableID(
                        sourceLineIndex: sourceLineIndex,
                        timestampOffset: timestamp.offset,
                        startTime: timestamp.time
                    ),
                    startTime: timestamp.time,
                    text: lyricText
                ),
                sourceLineIndex: sourceLineIndex,
                timestampOffset: timestamp.offset
            )
        }
    }

    private func isLyricTimestamp(_ stamp: String) -> Bool {
        let parts = stamp.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else { return false }
        return Double(parts[0]) != nil
    }

    private func parseTimestamp(_ stamp: String) throws -> TimeInterval {
        let parts = stamp.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            throw LyricParseError.invalidTimestamp(stamp)
        }

        let timestamp = minutes * 60 + seconds
        guard minutes.isFinite,
              seconds.isFinite,
              timestamp.isFinite,
              minutes >= 0,
              seconds >= 0,
              seconds < 60,
              timestamp <= Self.maximumTimestampSeconds else {
            throw LyricParseError.invalidTimestamp(stamp)
        }

        return timestamp
    }

    private func stableID(
        sourceLineIndex: Int,
        timestampOffset: Int,
        startTime: TimeInterval
    ) -> String {
        let milliseconds = Int((startTime * 1_000).rounded())
        return "lrc:\(sourceLineIndex):\(timestampOffset):\(milliseconds)"
    }
}

extension Array where Element == TimedLyricLine {
    func activeLineID(at playbackTime: TimeInterval) -> TimedLyricLine.ID? {
        guard !isEmpty else { return nil }

        var lowerBound = 0
        var upperBound = count

        while lowerBound < upperBound {
            let middle = (lowerBound + upperBound) / 2
            if self[middle].startTime <= playbackTime {
                lowerBound = middle + 1
            } else {
                upperBound = middle
            }
        }

        guard lowerBound > 0 else { return nil }

        let candidate = self[lowerBound - 1]
        return candidate.contains(playbackTime) ? candidate.id : nil
    }
}

extension SongTextDocument {
    func parsedTimedLyrics(using parser: LRCParser = LRCParser()) throws -> [TimedLyricLine] {
        try parser.parse(text)
    }
}

private struct ParsedTimedLyricLine {
    var lyricLine: TimedLyricLine
    var sourceLineIndex: Int
    var timestampOffset: Int
}
