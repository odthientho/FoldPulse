import Foundation
@testable import FoldPulseCore

enum Fixture {
    static let london = TimeZone(identifier: "Europe/London")!
    static let newYork = TimeZone(identifier: "America/New_York")!
    static let tokyo = TimeZone(identifier: "Asia/Tokyo")!
    static let utc = TimeZone(identifier: "UTC")!

    /// Builds a Date from an ISO-8601 string with offset, e.g. "2026-11-09T14:04:00Z".
    static func date(_ iso: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        guard let d = f.date(from: iso) else { fatalError("bad date \(iso)") }
        return d
    }

    static func event(_ type: EventType = .fold, _ source: DetectionSource = .hinge, at iso: String,
                      tz: TimeZone = london, deleted: Bool = false, duplicateOf: UUID? = nil) -> FoldEvent {
        FoldEvent(type: type, source: source, timestamp: date(iso), timeZone: tz,
                  deletedAt: deleted ? date(iso) : nil, duplicateOf: duplicateOf)
    }
}
