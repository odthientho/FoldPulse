import Foundation

/// CSV and JSON export (PRIVACY_REVIEW P-4). Export is always user-initiated;
/// nothing here touches the network.
public enum Exporter {
    public static let csvHeader = "id,type,source,timestamp_utc,time_zone,local_day,note,edited,duplicate_of,gap_start_utc,gap_end_utc"

    /// CSV of non-deleted events (tombstones are omitted), oldest first.
    public static func csv(_ events: [FoldEvent]) -> String {
        let iso = isoFormatter()
        var lines = [csvHeader]
        for e in events.filter({ $0.deletedAt == nil }).sorted(by: { $0.timestamp < $1.timestamp }) {
            let fields = [
                e.id.uuidString, e.type.rawValue, e.source.rawValue, iso.string(from: e.timestamp), e.timeZoneID,
                e.localDay.description, e.note ?? "", e.isEdited ? "true" : "false", e.duplicateOf?.uuidString ?? "",
                e.inferredIntervalStart.map(iso.string(from:)) ?? "", e.inferredIntervalEnd.map(iso.string(from:)) ?? "",
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Escapes one CSV field, neutralising spreadsheet formula injection: a field
    /// starting with `= + - @`, tab or carriage return is prefixed with `'`.
    public static func escape(_ field: String) -> String {
        var value = field
        if let first = value.unicodeScalars.first, "=+-@\t\r".unicodeScalars.contains(first) {
            value = "'" + value
        }
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            value = "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    /// Full-fidelity JSON (including tombstones, needed for a future merge-import).
    /// Dates are ISO-8601 UTC with millisecond precision.
    public struct Document: Codable, Equatable, Sendable {
        public static let formatIdentifier = "foldpulse-export"
        public var format: String
        public var version: Int
        public var exportedAt: Date
        public var events: [FoldEvent]
    }

    public static func json(_ events: [FoldEvent], exportedAt: Date) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(isoFormatter().string(from: date))
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        return try encoder.encode(Document(format: Document.formatIdentifier, version: 1, exportedAt: exportedAt, events: sorted))
    }

    public static func decodeJSON(_ data: Data) throws -> Document {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = isoFormatter().date(from: raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date \(raw)")
            }
            return date
        }
        return try decoder.decode(Document.self, from: data)
    }

    private static func isoFormatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }
}
