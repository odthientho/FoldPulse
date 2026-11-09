import Foundation
import SwiftData

/// Version 1 of the on-device schema (docs/DATABASE_DESIGN.md).
/// Every future change adds a new `VersionedSchema` and a migration stage,
/// so existing users' data is never dropped.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [StoredEvent.self] }

    /// One fold/unfold event. Mirrors `FoldPulseCore.FoldEvent`.
    @Model
    final class StoredEvent {
        #Index<StoredEvent>([\.timestamp], [\.localDay])

        @Attribute(.unique) var id: UUID
        /// `EventType.rawValue` ("fold" / "unfold").
        var typeRaw: String
        /// `DetectionSource.rawValue` ("hinge" / "shortcut" / "manual" / "inferred").
        var sourceRaw: String
        var timestamp: Date
        var timeZoneID: String
        /// Local day at capture, "YYYY-MM-DD" (indexed for daily queries).
        var localDay: String
        var note: String?
        var createdAt: Date
        var updatedAt: Date
        var isEdited: Bool
        /// Tombstone — set instead of deleting.
        var deletedAt: Date?
        var duplicateOf: UUID?
        var inferredIntervalStart: Date?
        var inferredIntervalEnd: Date?

        init(id: UUID, typeRaw: String, sourceRaw: String, timestamp: Date, timeZoneID: String, localDay: String,
             note: String?, createdAt: Date, updatedAt: Date, isEdited: Bool, deletedAt: Date?, duplicateOf: UUID?,
             inferredIntervalStart: Date?, inferredIntervalEnd: Date?) {
            self.id = id
            self.typeRaw = typeRaw
            self.sourceRaw = sourceRaw
            self.timestamp = timestamp
            self.timeZoneID = timeZoneID
            self.localDay = localDay
            self.note = note
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.isEdited = isEdited
            self.deletedAt = deletedAt
            self.duplicateOf = duplicateOf
            self.inferredIntervalStart = inferredIntervalStart
            self.inferredIntervalEnd = inferredIntervalEnd
        }
    }
}

typealias StoredEvent = SchemaV1.StoredEvent

/// Migration plan: no stages yet (V1 is the first version).
enum FoldPulseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
