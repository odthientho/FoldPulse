import XCTest
@testable import FoldPulseCore

/// Regression tests for findings from the Phase 3 agent reviews.
final class ReviewFixTests: XCTestCase {
    func testImpossibleDatesAreRejected() {
        XCTAssertNil(LocalDay(string: "2026-02-31"))
        XCTAssertNil(LocalDay(string: "2026-02-29"))
        XCTAssertNotNil(LocalDay(string: "2028-02-29"))
        XCTAssertNil(LocalDay(string: "2026-04-31"))
        XCTAssertNil(LocalDay(string: "2100-02-29"), "2100 is not a leap year")
        XCTAssertNotNil(LocalDay(string: "2000-02-29"), "2000 is a leap year")
    }

    func testSetTimestampRecomputesDayInCaptureZone() {
        var event = Fixture.event(.fold, .hinge, at: "2026-11-09T15:00:00Z", tz: Fixture.newYork) // Nov 9, 10:00 NY
        XCTAssertEqual(event.localDay, LocalDay(year: 2026, month: 11, day: 9))
        event.setTimestamp(Fixture.date("2026-11-10T06:00:00Z")) // Nov 10 01:00 NY
        XCTAssertEqual(event.localDay, LocalDay(year: 2026, month: 11, day: 10))
        XCTAssertEqual(event.timeZoneID, "America/New_York", "the capture zone never changes on edit")
    }

    func testStoredDayIsUsedWithoutRecomputation() {
        let stored = LocalDay(year: 2026, month: 11, day: 1)
        let event = FoldEvent(type: .fold, source: .hinge, timestamp: Fixture.date("2026-11-09T12:00:00Z"),
                              timeZone: Fixture.london, localDay: stored)
        XCTAssertEqual(event.localDay, stored)
    }

    func testUnknownTimeZoneFallsBackToZeroOffset() {
        var event = Fixture.event(at: "2026-11-09T12:00:00Z")
        event.timeZoneID = "Mars/Olympus_Mons"
        // Check the offset, not the name: Foundation calls this zone "GMT" (CI run 3).
        XCTAssertEqual(event.timeZone.secondsFromGMT(for: event.timestamp), 0)
        XCTAssertEqual(LocalDay(date: Fixture.date("2026-11-09T23:30:00Z"), timeZone: event.timeZone),
                       LocalDay(year: 2026, month: 11, day: 9))
    }

    func testDayStartIsInsideTheDayEvenWhenMidnightIsSkipped() {
        // Chile moves clocks forward at midnight in early September; every day's
        // start must still fall on that same local day.
        let santiago = TimeZone(identifier: "America/Santiago")!
        for day in LocalDay.range(from: LocalDay(year: 2026, month: 9, day: 1), through: LocalDay(year: 2026, month: 9, day: 10)) {
            XCTAssertEqual(LocalDay(date: day.start(in: santiago), timeZone: santiago), day, "\(day)")
        }
    }

    func testInferredFirstEventStartsTracking() {
        let events = [Fixture.event(.fold, .inferred, at: "2026-11-05T12:00:00Z"),
                      Fixture.event(.fold, .hinge, at: "2026-11-06T12:00:00Z")]
        XCTAssertEqual(Statistics.firstTrackedDay(events), LocalDay(year: 2026, month: 11, day: 5))
    }

    func testIncludeInferredIsPassedThroughToSnapshot() {
        let now = Fixture.date("2026-11-09T14:00:00Z")
        let events = [Fixture.event(.fold, .hinge, at: "2026-11-09T10:00:00Z"),
                      Fixture.event(.fold, .inferred, at: "2026-11-09T11:00:00Z")]
        XCTAssertEqual(WidgetSnapshot.make(from: events, now: now, timeZone: Fixture.london).totalSinceInstall, 1)
        XCTAssertEqual(WidgetSnapshot.make(from: events, now: now, timeZone: Fixture.london, includeInferred: true).totalSinceInstall, 2)
    }

    func testDashboardStatsWeekEndsToday() {
        let now = Fixture.date("2026-11-09T14:00:00Z")
        let events = [Fixture.event(.fold, .hinge, at: "2026-11-03T10:00:00Z"),
                      Fixture.event(.fold, .shortcut, at: "2026-11-09T10:00:00Z"),
                      Fixture.event(.fold, .manual, at: "2026-11-02T10:00:00Z")] // outside the 7-day window
        let stats = DashboardStats.make(from: events, now: now, timeZone: Fixture.london)
        XCTAssertEqual(stats.lastSevenDays.count, 7)
        XCTAssertEqual(stats.lastSevenDays.first?.day, LocalDay(year: 2026, month: 11, day: 3))
        XCTAssertEqual(stats.lastSevenDays.last?.day, LocalDay(year: 2026, month: 11, day: 9))
        XCTAssertEqual(stats.lastSevenDays.map(\.count), [1, 0, 0, 0, 0, 0, 1])
        XCTAssertEqual(stats.coverage, Coverage(hinge: 1, shortcut: 1, manual: 0, gaps: 0))
        XCTAssertEqual(stats.snapshot.totalSinceInstall, 3)
    }
}
