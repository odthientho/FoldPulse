import XCTest
@testable import FoldPulseCore

final class StatisticsTests: XCTestCase {
    func testTotalsExcludeGapsDeletedAndDuplicates() {
        let kept = Fixture.event(.fold, .hinge, at: "2026-11-09T10:00:00Z")
        let events = [
            kept,
            Fixture.event(.fold, .shortcut, at: "2026-11-09T11:00:00Z"),
            Fixture.event(.fold, .manual, at: "2026-11-09T12:00:00Z"),
            Fixture.event(.fold, .inferred, at: "2026-11-09T13:00:00Z"),
            Fixture.event(.fold, .hinge, at: "2026-11-09T14:00:00Z", deleted: true),
            Fixture.event(.fold, .shortcut, at: "2026-11-09T10:00:02Z", duplicateOf: kept.id),
            Fixture.event(.unfold, .hinge, at: "2026-11-09T10:05:00Z"),
        ]
        XCTAssertEqual(Statistics.total(events), 3)
        XCTAssertEqual(Statistics.total(events, includeInferred: true), 4)
        XCTAssertEqual(Statistics.total(events, type: .unfold), 1)
    }

    func testEventKeepsCaptureDayAfterTravel() {
        // Folded at 23:30 in New York; the user later flies to Tokyo.
        let event = Fixture.event(.fold, .hinge, at: "2026-11-10T04:30:00Z", tz: Fixture.newYork)
        XCTAssertEqual(event.localDay, LocalDay(year: 2026, month: 11, day: 9))
        XCTAssertEqual(Statistics.countsByDay([event])[LocalDay(year: 2026, month: 11, day: 9)], 1)
    }

    func testDailyAverageUsesFullDaysIncludingZeroDays() {
        // Tracking began Nov 5. Today is Nov 9 → full days Nov 5…8 (4 days), Nov 7 has zero.
        let events = [
            Fixture.event(at: "2026-11-05T09:00:00Z"), Fixture.event(at: "2026-11-05T10:00:00Z"),
            Fixture.event(at: "2026-11-06T09:00:00Z"), Fixture.event(at: "2026-11-06T10:00:00Z"),
            Fixture.event(at: "2026-11-08T09:00:00Z"), Fixture.event(at: "2026-11-08T10:00:00Z"),
            Fixture.event(at: "2026-11-09T09:00:00Z"), // today: excluded from the average
        ]
        let today = LocalDay(year: 2026, month: 11, day: 9)
        XCTAssertEqual(Statistics.dailyAverage(events, today: today) ?? -1, 6.0 / 4.0, accuracy: 0.0001)
    }

    func testDailyAverageNilOnFirstDay() {
        let events = [Fixture.event(at: "2026-11-09T09:00:00Z")]
        XCTAssertNil(Statistics.dailyAverage(events, today: LocalDay(year: 2026, month: 11, day: 9)))
        XCTAssertNil(Statistics.dailyAverage([], today: LocalDay(year: 2026, month: 11, day: 9)))
    }

    func testDailyAverageWindowIsCappedAtSevenDays() {
        var events: [FoldEvent] = []
        for day in 1...20 { events.append(Fixture.event(at: "2026-10-\(day < 10 ? "0" : "")\(day)T12:00:00Z")) }
        events.append(contentsOf: (0..<14).map { _ in Fixture.event(at: "2026-10-19T13:00:00Z") })
        // Today Oct 21 → window Oct 14…20 = 7 days, 7 base folds + 14 extra = 21 → 3.0
        XCTAssertEqual(Statistics.dailyAverage(events, today: LocalDay(year: 2026, month: 10, day: 21)) ?? -1, 3.0, accuracy: 0.0001)
    }

    func testSeriesIncludesZeroDaysInOrder() {
        let events = [Fixture.event(at: "2026-11-03T12:00:00Z"), Fixture.event(at: "2026-11-05T12:00:00Z")]
        let days = LocalDay.range(from: LocalDay(year: 2026, month: 11, day: 3), through: LocalDay(year: 2026, month: 11, day: 5))
        XCTAssertEqual(Statistics.series(events, days: days).map(\.count), [1, 0, 1])
    }

    func testBusiestDayEarliestWinsTie() {
        let events = [Fixture.event(at: "2026-11-03T12:00:00Z"), Fixture.event(at: "2026-11-05T12:00:00Z")]
        let days = LocalDay.range(from: LocalDay(year: 2026, month: 11, day: 3), through: LocalDay(year: 2026, month: 11, day: 5))
        XCTAssertEqual(Statistics.busiestDay(events, days: days)?.day, LocalDay(year: 2026, month: 11, day: 3))
        XCTAssertNil(Statistics.busiestDay([], days: days))
    }

    func testCoverageCountsRecordedFoldsOnlyAndReportsGaps() {
        let day = LocalDay(year: 2026, month: 11, day: 9)
        let events = [
            Fixture.event(.fold, .hinge, at: "2026-11-09T09:00:00Z"),
            Fixture.event(.fold, .hinge, at: "2026-11-09T10:00:00Z"),
            Fixture.event(.fold, .shortcut, at: "2026-11-09T11:00:00Z"),
            Fixture.event(.fold, .manual, at: "2026-11-09T12:00:00Z"),
            Fixture.event(.fold, .inferred, at: "2026-11-09T13:00:00Z"),
            Fixture.event(.unfold, .manual, at: "2026-11-09T14:00:00Z"),
        ]
        let coverage = Statistics.coverage(events, days: [day])
        XCTAssertEqual(coverage, Coverage(hinge: 2, shortcut: 1, manual: 1, gaps: 1))
        XCTAssertEqual(coverage.recordedFolds, 4)
        XCTAssertEqual(coverage.countedForYouShare ?? -1, 0.75, accuracy: 0.0001)
        XCTAssertNil(Coverage().countedForYouShare)
    }
}
