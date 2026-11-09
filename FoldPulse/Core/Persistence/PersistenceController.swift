import Foundation
import SwiftData

/// Creates the SwiftData container. Local only: CloudKit is explicitly off
/// (PRIVACY_REVIEW P-1, DECISIONS T-3).
enum PersistenceController {
    static func makeContainer(inMemory: Bool = false, url: URL = AppGroup.storeURL) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: FoldPulseMigrationPlan.self, configurations: [configuration])
    }
}
