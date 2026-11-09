import Foundation

/// One line of the log file. Times: `t` = wall clock (Unix seconds),
/// `mono` = seconds since device boot (monotonic, used for intervals).
struct ProbeRecord: Codable {
    var t: Double
    var mono: Double
    var kind: String          // launch | hinge | scene | size | shortcut | note
    var status: String?       // hinge status, or "closed"/"opened" for shortcuts
    var angleDeg: Double?
    var detail: String?
    var condition: String?
}

/// Append-only JSON-lines log in the app's Documents folder.
/// Written with "complete until first user authentication" protection so that
/// background Shortcut runs can write while the phone is locked (spike step 8).
final class ProbeLog: @unchecked Sendable {
    static let shared = ProbeLog()
    static let conditionKey = "probeCondition"

    let fileURL: URL
    private let queue = DispatchQueue(label: "foldprobe.log")
    private let encoder = JSONEncoder()
    private(set) var lastError: String?

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("foldprobe-log.jsonl")
    }

    private func makeRecord(kind: String, status: String?, angleDeg: Double?, detail: String?) -> ProbeRecord {
        ProbeRecord(
            t: Date().timeIntervalSince1970,
            mono: ProcessInfo.processInfo.systemUptime,
            kind: kind,
            status: status,
            angleDeg: angleDeg,
            detail: detail,
            condition: UserDefaults.standard.string(forKey: Self.conditionKey)
        )
    }

    /// Fire-and-forget append (used from the UI).
    func append(kind: String, status: String? = nil, angleDeg: Double? = nil, detail: String? = nil) {
        // Timestamp is taken now, on the caller's thread, not when the write happens.
        let record = makeRecord(kind: kind, status: status, angleDeg: angleDeg, detail: detail)
        queue.async { _ = self.write(record) }
    }

    /// Blocking append that reports success (used by the background intents).
    @discardableResult
    func appendNow(kind: String, status: String? = nil, detail: String? = nil) -> Bool {
        let record = makeRecord(kind: kind, status: status, angleDeg: nil, detail: detail)
        return queue.sync { write(record) }
    }

    private func write(_ record: ProbeRecord) -> Bool {
        do {
            var data = try encoder.encode(record)
            data.append(0x0A)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            } else {
                try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            }
            return true
        } catch {
            lastError = String(describing: error)
            return false
        }
    }

    /// Last `n` lines, for the on-screen preview.
    func tail(_ n: Int) -> [String] {
        queue.sync {
            guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
            return Array(text.split(separator: "\n").suffix(n)).map(String.init)
        }
    }

    func reset() {
        queue.sync { try? FileManager.default.removeItem(at: fileURL) }
    }
}
