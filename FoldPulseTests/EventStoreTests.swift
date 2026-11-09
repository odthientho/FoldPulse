import XCTest
import SwiftData
import FoldPulseCore
@testable import FoldPulse

/// Persistence round-trips against an in-memory SwiftData store.
final class EventStoreTests: XCTestCase {
    private func makeStore() throws -> EventStore {
        EventStore(modelContainer: try PersistenceController.makeContainer(inMemory: true))
    }

    private let newYork = TimeZone(identifier: "America/New_York")!

    func testAddAndFetchPreservesEveryField() async throws {
        let store = try makeStore()
        let event = FoldEvent(type: .fold, source: .shortcut, timestamp: Date(timeIntervalSince1970: 1_794_200_000),
                              timeZone: newYork, note: "on the train", isEdited: true,
                              inferredIntervalStart: Date(timeIntervalSince1970: 1_794_190_000),
                              inferredIntervalEnd: Date(timeIntervalSince1970: 1_794_210_000))
        try await store.add(event)
        let fetched = try await store.allEvents()
        XCTAssertEqual(fetched, [event])
        XCTAssertEqual(fetched.first?.timeZoneID, "America/New_York")
    }

    func testEventsAreReturnedInChronologicalOrder() async throws {
        let store = try makeStore()
        let late = FoldEvent(type: .fold, source: .hinge, timestamp: Date(timeIntervalSince1970: 2_000))
        let early = FoldEvent(type: .unfold, source: .hinge, timestamp: Date(timeIntervalSince1970: 1_000))
        try await store.add(late)
        try await store.add(early)
        let ids = try await store.allEvents().map(\.id)
        XCTAssertEqual(ids, [early.id, late.id])
    }

    func testUpdateBumpsUpdatedAt() async throws {
        let store = try makeStore()
        var event = FoldEvent(type: .fold, source: .hinge, timestamp: Date(timeIntervalSince1970: 1_000))
        try await store.add(event)
        event.note = "edited"
        event.isEdited = true
        let editTime = Date(timeIntervalSince1970: 5_000)
        try await store.update(event, now: editTime)
        let fetched = try await store.allEvents().first
        XCTAssertEqual(fetched?.note, "edited")
        XCTAssertEqual(fetched?.isEdited, true)
        XCTAssertEqual(fetched?.updatedAt, editTime)
    }

    func testSoftDeleteKeepsTombstone() async throws {
        let store = try makeStore()
        let event = FoldEvent(type: .fold, source: .manual, timestamp: Date(timeIntervalSince1970: 1_000))
        try await store.add(event)
        try await store.softDelete(id: event.id, now: Date(timeIntervalSince1970: 9_000))
        let visible = try await store.allEvents()
        let all = try await store.allEvents(includeDeleted: true)
        XCTAssertTrue(visible.isEmpty)
        XCTAssertEqual(all.first?.deletedAt, Date(timeIntervalSince1970: 9_000))
        let total = try await store.count()
        XCTAssertEqual(total, 1, "tombstones stay in the database")
    }

    func testUpdatingMissingEventThrows() async throws {
        let store = try makeStore()
        let ghost = FoldEvent(type: .fold, source: .hinge, timestamp: .now)
        do {
            try await store.update(ghost)
            XCTFail("expected notFound")
        } catch let error as EventStore.StoreError {
            XCTAssertEqual(error, .notFound(ghost.id))
        }
    }

    func testDeleteAllEmptiesTheStore() async throws {
        let store = try makeStore()
        for i in 0..<10 {
            try await store.add(FoldEvent(type: .fold, source: .hinge, timestamp: Date(timeIntervalSince1970: Double(i))))
        }
        try await store.deleteAll()
        let total = try await store.count()
        XCTAssertEqual(total, 0)
    }
}
