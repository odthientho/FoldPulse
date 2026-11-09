import Foundation
import SwiftData

/// Creates the SwiftData container. Local only: CloudKit is explicitly off
/// (PRIVACY_REVIEW P-1, DECISIONS T-3).
enum PersistenceController {
    enum SetupError: Error, CustomStringConvertible {
        case appGroupUnavailable

        var description: String {
            "The FoldPulse App Group is not available, so data can't be stored safely. Reinstall FoldPulse; if this continues, contact support."
        }
    }

    /// A file-backed container at an explicit location (UI tests, migration fixtures).
    static func makeContainer(url: URL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: FoldPulseMigrationPlan.self, configurations: [configuration])
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            guard let directory = AppGroup.storeDirectory, let url = AppGroup.storeURL else { throw SetupError.appGroupUnavailable }
            try prepareProtectedDirectory(directory)
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: FoldPulseMigrationPlan.self, configurations: [configuration])
    }

    /// Creates `directory` with `completeUntilFirstUserAuthentication` protection so the
    /// store (and its -wal/-shm files) can be written by background intents while the
    /// device is locked, but stay encrypted until the first unlock (PRIVACY_REVIEW P-3).
    static func prepareProtectedDirectory(_ directory: URL) throws {
        let protection = [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: protection)
        try FileManager.default.setAttributes(protection, ofItemAtPath: directory.path)
    }
}
