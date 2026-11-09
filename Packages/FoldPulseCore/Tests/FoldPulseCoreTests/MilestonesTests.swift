import XCTest
@testable import FoldPulseCore

final class MilestonesTests: XCTestCase {
    func testNextAndProgress() {
        XCTAssertEqual(Milestones.next(after: 0), 100)
        XCTAssertEqual(Milestones.next(after: 1_000), 5_000)
        XCTAssertEqual(Milestones.next(after: 1_284), 5_000)
        XCTAssertNil(Milestones.next(after: 100_000))
        XCTAssertEqual(Milestones.progress(total: 1_284) ?? -1, 0.2568, accuracy: 0.0001)
    }

    func testCelebratedOnceEvenAfterDeletions() {
        var celebrated: Set<Int> = []
        celebrated.formUnion(Milestones.toCelebrate(total: 510, alreadyCelebrated: celebrated))
        XCTAssertEqual(celebrated, [100, 500])
        // The user deletes events and the total drops below 500, then rises again.
        XCTAssertEqual(Milestones.toCelebrate(total: 490, alreadyCelebrated: celebrated), [])
        XCTAssertEqual(Milestones.toCelebrate(total: 505, alreadyCelebrated: celebrated), [])
        XCTAssertEqual(Milestones.toCelebrate(total: 1_000, alreadyCelebrated: celebrated), [1_000])
    }
}
