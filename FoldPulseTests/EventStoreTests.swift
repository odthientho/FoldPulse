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

    func testAddingAnExistingIDIsRejectedNotOverwritten() async throws {
        let store = try makeStore()
        let original = FoldEvent(type: .fold, source: .hinge, timestamp: Date(timeIntervalSince1970: 1_000), note: "original")
        try await store.add(original)
        var clash = original
        clash.note = "overwrite attempt"
        do {
            try await store.add(clash)
            XCTFail("expected duplicateID")
        } catch let error as EventStore.StoreError {
            XCTAssertEqual(error, .duplicateID(original.id))
        }
        let notes = try await store.allEvents().map(\.note)
        XCTAssertEqual(notes, ["original"])
    }

    func testBatchAddSavesAllEvents() async throws {
        let store = try makeStore()
        let events = (0..<50).map { FoldEvent(type: $0 % 2 == 0 ? .fold : .unfold, source: .hinge, timestamp: Date(timeIntervalSince1970: Double($0))) }
        try await store.add(contentsOf: events)
        let total = try await store.count()
        XCTAssertEqual(total, 50)
    }

    func testRowsWithUnknownValuesAreSkippedNotGuessed() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        context.insert(StoredEvent(id: UUID(), typeRaw: "spin", sourceRaw: "hinge", timestamp: .now, timeZoneID: "UTC",
                                   localDay: "2026-11-09", note: nil, createdAt: .now, updatedAt: .now, isEdited: false,
                                   deletedAt: nil, duplicateOf: nil, inferredIntervalStart: nil, inferredIntervalEnd: nil))
        try context.save()
        let store = EventStore(modelContainer: container)
        let events = try await store.allEvents()
        XCTAssertTrue(events.isEmpty)
    }

    func testLoadStateExcludesDuplicatesFromRecentEvents() async throws {
        let store = try makeStore()
        let kept = FoldEvent(type: .fold, source: .hinge, timestamp: .now.addingTimeInterval(-120))
        let merged = FoldEvent(type: .fold, source: .shortcut, timestamp: .now.addingTimeInterval(-118), duplicateOf: kept.id)
        try await store.add(contentsOf: [kept, merged])
        let state = try await store.loadState(now: .now, timeZone: .current)
        XCTAssertEqual(state.recentEvents.map(\.id), [kept.id])
        XCTAssertEqual(state.dashboard.snapshot.totalSinceInstall, 1)
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
