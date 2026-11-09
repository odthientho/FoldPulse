import Foundation
import FoldPulseCore

/// Reads and writes the widget snapshot JSON in the App Group.
///
/// Protection is `completeUntilFirstUserAuthentication`: readable by widgets on the
/// Lock Screen and writable by background intents while the phone is locked
/// (PRIVACY_REVIEW P-3), but encrypted until the first unlock after a reboot.
enum SnapshotFile {
    static var defaultURL: URL { AppGroup.containerURL.appendingPathComponent(WidgetSnapshot.fileName) }

    static func read(from url: URL = defaultURL) -> WidgetSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return WidgetSnapshot.decode(data)
    }

    static func write(_ snapshot: WidgetSnapshot, to url: URL = defaultURL) throws {
        let data = try snapshot.encoded()
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
