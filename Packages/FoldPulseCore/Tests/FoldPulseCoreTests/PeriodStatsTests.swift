import XCTest
@testable import FoldPulseCore

final class PeriodStatsTests: XCTestCase {
    private let now = Fixture.date("2026-11-09T14:30:00Z") // Monday, London (GMT)

    private func folds(_ isos: [String]) -> [FoldEvent] { isos.map { Fixture.event(.fold, .hinge, at: $0) } }

    func testDayHasHourlyBucketsAndYesterdayComparison() {
        let events = folds(["2026-11-08T09:00:00Z", "2026-11-09T09:10:00Z", "2026-11-09T09:40:00Z", "2026-11-09T14:05:00Z"])
        let s = Statistics.summary(events, period: .day, now: now, timeZone: Fixture.london)
        XCTAssertEqual(s.buckets.count, 24)
        XCTAssertEqual(s.buckets[9].count, 2)
        XCTAssertEqual(s.buckets[14].count, 1)
        XCTAssertTrue(s.buckets[14].isCurrent)
        XCTAssertEqual(s.total, 3)
        XCTAssertEqual(s.previousTotal, 1)
    }

    func testWeekCoversSevenDaysWithFullDayAverageAndBusiestDay() {
        let events = folds(["2026-11-03T10:00:00Z", "2026-11-06T10:00:00Z", "2026-11-06T11:00:00Z", "2026-11-09T10:00:00Z"])
        let s = Statistics.summary(events, period: .week, now: now, timeZone: Fixture.london)
        XCTAssertEqual(s.buckets.count, 7)
        XCTAssertEqual(s.buckets.first?.key, .day(LocalDay(year: 2026, month: 11, day: 3)))
        XCTAssertEqual(s.total, 4)
        XCTAssertEqual(s.busiestDay, DayCount(day: LocalDay(year: 2026, month: 11, day: 6), count: 2))
        // Full days Nov 3…8 (6 days, tracking began Nov 3): 3 folds → 0.5/day; today excluded.
        XCTAssertEqual(s.averagePerFullDay ?? -1, 0.5, accuracy: 0.0001)
        XCTAssertNil(s.previousTotal, "tracking began within this week")
    }

    func testMonthAndYearBuckets() {
        let events = folds(["2026-10-15T10:00:00Z", "2026-11-01T10:00:00Z", "2026-11-09T10:00:00Z"])
        let month = Statistics.summary(events, period: .month, now: now, timeZone: Fixture.london)
        XCTAssertEqual(month.buckets.count, 9)
        XCTAssertEqual(month.total, 2)
        XCTAssertEqual(month.previousTotal, 1, "October had one fold")
        let year = Statistics.summary(events, period: .year, now: now, timeZone: Fixture.london)
        XCTAssertEqual(year.buckets.count, 11)
        XCTAssertEqual(year.buckets[9].count, 1)
        XCTAssertEqual(year.buckets[10].count, 2)
        XCTAssertTrue(year.buckets[10].isCurrent)
        XCTAssertNil(year.previousTotal)
    }

    func testEmptyLogHasNoAveragesOrComparisons() {
        let s = Statistics.summary([], period: .week, now: now, timeZone: Fixture.london)
        XCTAssertEqual(s.total, 0)
        XCTAssertNil(s.averagePerFullDay)
        XCTAssertNil(s.previousTotal)
        XCTAssertNil(s.busiestDay)
    }
}
