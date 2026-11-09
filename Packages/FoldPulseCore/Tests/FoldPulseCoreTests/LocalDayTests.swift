import XCTest
@testable import FoldPulseCore

final class LocalDayTests: XCTestCase {
    func testDescriptionAndParsingRoundTrip() {
        let day = LocalDay(year: 2026, month: 11, day: 9)
        XCTAssertEqual(day.description, "2026-11-09")
        XCTAssertEqual(LocalDay(string: "2026-11-09"), day)
        XCTAssertNil(LocalDay(string: "2026-13-01"))
        XCTAssertNil(LocalDay(string: "nonsense"))
    }

    func testSameInstantIsDifferentDayInDifferentZones() {
        // 2026-11-09 23:30 in New York is already Nov 10 in Tokyo.
        let instant = Fixture.date("2026-11-10T04:30:00Z")
        XCTAssertEqual(LocalDay(date: instant, timeZone: Fixture.newYork), LocalDay(year: 2026, month: 11, day: 9))
        XCTAssertEqual(LocalDay(date: instant, timeZone: Fixture.tokyo), LocalDay(year: 2026, month: 11, day: 10))
    }

    func testAddingDaysAcrossDSTAndMonthAndYearBoundaries() {
        let springForward = LocalDay(year: 2026, month: 3, day: 7)   // US DST starts Mar 8 2026
        XCTAssertEqual(springForward.adding(days: 1), LocalDay(year: 2026, month: 3, day: 8))
        XCTAssertEqual(springForward.adding(days: 2), LocalDay(year: 2026, month: 3, day: 9))
        XCTAssertEqual(LocalDay(year: 2026, month: 12, day: 31).adding(days: 1), LocalDay(year: 2027, month: 1, day: 1))
        XCTAssertEqual(LocalDay(year: 2028, month: 3, day: 1).adding(days: -1), LocalDay(year: 2028, month: 2, day: 29))
    }

    func testRangeAndDistance() {
        let a = LocalDay(year: 2026, month: 10, day: 30)
        let b = LocalDay(year: 2026, month: 11, day: 2)
        XCTAssertEqual(a.days(until: b), 3)
        XCTAssertEqual(LocalDay.range(from: a, through: b).map(\.description),
                       ["2026-10-30", "2026-10-31", "2026-11-01", "2026-11-02"])
        XCTAssertTrue(LocalDay.range(from: b, through: a).isEmpty)
    }

    func testFallBackRepeatedHourStaysOnSameDay() {
        // 2026-11-01 01:30 happens twice in New York (EDT then EST).
        let first = Fixture.date("2026-11-01T05:30:00Z")
        let second = Fixture.date("2026-11-01T06:30:00Z")
        XCTAssertEqual(LocalDay(date: first, timeZone: Fixture.newYork), LocalDay(year: 2026, month: 11, day: 1))
        XCTAssertEqual(LocalDay(date: second, timeZone: Fixture.newYork), LocalDay(year: 2026, month: 11, day: 1))
    }

    func testStartOfDayHandles23HourDay() {
        let day = LocalDay(year: 2026, month: 3, day: 8)
        let start = day.start(in: Fixture.newYork)
        let next = day.adding(days: 1).start(in: Fixture.newYork)
        XCTAssertEqual(next.timeIntervalSince(start), 23 * 3600)
    }

    func testCodableAsString() throws {
        let day = LocalDay(year: 2026, month: 1, day: 5)
        let data = try JSONEncoder().encode([day])
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "[\"2026-01-05\"]")
        XCTAssertEqual(try JSONDecoder().decode([LocalDay].self, from: data), [day])
    }
}
