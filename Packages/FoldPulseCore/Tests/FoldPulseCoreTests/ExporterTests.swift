import XCTest
@testable import FoldPulseCore

final class ExporterTests: XCTestCase {
    func testFormulaInjectionIsNeutralised() {
        XCTAssertEqual(Exporter.escape("=HYPERLINK(\"x\")"), "\"'=HYPERLINK(\"\"x\"\")\"")
        XCTAssertEqual(Exporter.escape("+1"), "'+1")
        XCTAssertEqual(Exporter.escape("-2"), "'-2")
        XCTAssertEqual(Exporter.escape("@SUM(A1)"), "'@SUM(A1)")
        XCTAssertEqual(Exporter.escape("plain note"), "plain note")
        XCTAssertEqual(Exporter.escape("a, b"), "\"a, b\"")
        XCTAssertEqual(Exporter.escape("line1\nline2"), "\"line1\nline2\"")
    }

    func testCSVOmitsTombstonesAndIsChronological() {
        var deleted = Fixture.event(.fold, .manual, at: "2026-11-09T09:00:00Z")
        deleted.deletedAt = Fixture.date("2026-11-09T09:01:00Z")
        var noted = Fixture.event(.unfold, .shortcut, at: "2026-11-09T11:00:00Z")
        noted.note = "=cmd"
        let early = Fixture.event(.fold, .hinge, at: "2026-11-09T10:00:00Z")
        let lines = Exporter.csv([noted, deleted, early]).split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], Exporter.csvHeader)
        XCTAssertTrue(lines[1].contains(",fold,hinge,2026-11-09T10:00:00.000Z,Europe/London,2026-11-09,"))
        XCTAssertTrue(lines[2].contains(",'=cmd,"), "note escaped")
    }

    func testJSONRoundTripKeepsEverythingIncludingTombstones() throws {
        var deleted = Fixture.event(.fold, .manual, at: "2026-11-09T09:00:00Z")
        deleted.deletedAt = Fixture.date("2026-11-09T09:01:00Z")
        let event = FoldEvent(type: .unfold, source: .hinge, timestamp: Date(timeIntervalSince1970: 1_794_200_000.123),
                              timeZone: Fixture.newYork, note: "x")
        let data = try Exporter.json([event, deleted], exportedAt: Fixture.date("2026-11-09T14:00:00Z"))
        let doc = try Exporter.decodeJSON(data)
        XCTAssertEqual(doc.format, "foldpulse-export")
        XCTAssertEqual(doc.version, 1)
        XCTAssertEqual(doc.events.count, 2)
        let decodedDeleted = try XCTUnwrap(doc.events.first { $0.id == deleted.id })
        let decodedEvent = try XCTUnwrap(doc.events.first { $0.id == event.id })
        XCTAssertEqual(decodedDeleted.deletedAt, deleted.deletedAt)
        XCTAssertEqual(decodedEvent.timestamp.timeIntervalSince1970, 1_794_200_000.123, accuracy: 0.001, "millisecond precision")
        XCTAssertEqual(decodedEvent.timeZoneID, "America/New_York")
        XCTAssertEqual(doc.events.map(\.timestamp), doc.events.map(\.timestamp).sorted(), "chronological")
    }
}
