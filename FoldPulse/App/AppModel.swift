import Foundation
import Observation
import UserNotifications
import FoldPulseCore

/// App-wide UI state: dashboard numbers, recent events, the hinge tracker and
/// the actions screens use. Database work happens in `EventStore`, off the main thread.
@MainActor
@Observable
final class AppModel {
    private(set) var dashboard: DashboardStats
    private(set) var recentEvents: [FoldEvent] = []
    private(set) var lastError: String?
    /// The most recent manual event, for Undo.
    private(set) var lastManualEvent: FoldEvent?
    /// The most recent counted event (Today's "Last:" row).
    var lastEvent: FoldEvent? { recentEvents.first { $0.source != .inferred } }
    /// A milestone to celebrate once (sheet on Today).
    var pendingMilestone: Int?
    /// True once a hinge reading has ever been received on this device.
    private(set) var hasSeenHinge: Bool

    let hinge: HingeTracker
    @ObservationIgnored let services: AppServices

    init(services: AppServices) {
        self.services = services
        self.hinge = HingeTracker()
        self.dashboard = .empty(now: .now, timeZone: .current)
        self.hasSeenHinge = services.settings.hasSeenHinge
        self.pendingMilestone = services.settings.pendingMilestone
        hinge.onEdge = { [weak self] edge in
            await self?.record(edge.type, source: .hinge, at: edge.at)
        }
        hinge.onHingeSeen = { [weak self] in
            guard let self, !self.hasSeenHinge else { return }
            self.hasSeenHinge = true
            self.services.settings.hasSeenHinge = true
        }
    }

    var settings: AppSettings { services.settings }

    /// Reloads state (statistics computed off the main thread) and refreshes the widget.
    func reload(appIsActive: Bool = true) async {
        do {
            let state = try await services.store.loadState(now: .now, timeZone: .current)
            apply(state)
            try services.snapshots.publish(state.dashboard.snapshot, appIsActive: appIsActive)
            checkSelfTest()
            // Also picks up milestones reached by background Shortcuts runs.
            _ = settings.claimMilestones(total: state.dashboard.snapshot.totalSinceInstall)
            pendingMilestone = settings.pendingMilestone
        } catch {
            lastError = String(describing: error)
        }
    }

    /// Records an event (any source) and refreshes everything.
    @discardableResult
    func record(_ type: EventType, source: DetectionSource, at time: Date = .now) async -> FoldEvent? {
        do {
            let outcome = try await services.record(type, source: source, at: time, appIsActive: true)
            apply(outcome.state)
            if !outcome.newMilestones.isEmpty { pendingMilestone = settings.pendingMilestone }
            if source == .manual { lastManualEvent = outcome.event }
            return outcome.event
        } catch {
            lastError = String(describing: error)
            return nil
        }
    }

    /// Undo for a manual event (tombstones it).
    func undo(_ event: FoldEvent) async {
        await delete(event)
        if lastManualEvent?.id == event.id { lastManualEvent = nil }
    }

    func delete(_ event: FoldEvent) async {
        do {
            try await services.store.delete(id: event.id, now: .now)
        } catch {
            lastError = String(describing: error) // kept on screen: no reload clears it (Phase 5 review)
            return
        }
        await reload()
    }

    func edit(_ event: FoldEvent) async {
        do {
            try await services.store.edit(event, now: .now)
        } catch {
            lastError = String(describing: error)
            return
        }
        await reload()
    }

    // MARK: Screens (Phase 4 batch C)

    func history(since: Date?, sources: Set<DetectionSource>?) async -> [FoldEvent] {
        do { return try await services.store.history(since: since, sources: sources) } catch {
            lastError = String(describing: error)
            return []
        }
    }

    func event(id: UUID) async -> FoldEvent? {
        try? await services.store.event(id: id)
    }

    func summary(_ period: InsightPeriod) async -> PeriodSummary? {
        try? await services.store.summary(period, now: .now, timeZone: .current)
    }

    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV", json = "JSON"
        var id: String { rawValue }
    }

    /// Writes an export file to a temporary location for the share sheet (PRIVACY_REVIEW P-4).
    func makeExportFile(_ format: ExportFormat) async throws -> URL {
        let events = try await services.store.exportEvents()
        let data: Data
        switch format {
        case .csv: data = Data(Exporter.csv(events).utf8)
        case .json: data = try Exporter.json(events, exportedAt: .now)
        }
        let day = LocalDay(date: .now, timeZone: .current)
        let directory = Self.exportDirectory
        Self.removeExports() // never leave older exports behind
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("FoldPulse-\(day).\(format.rawValue.lowercased())")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    static var exportDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Export", isDirectory: true)
    }

    /// Export files are deleted when the export sheet closes, at launch and on reset
    /// (PRIVACY_REVIEW P-4, Phase 4 privacy review).
    static func removeExports() {
        try? FileManager.default.removeItem(at: exportDirectory)
    }

    /// Settings → Reset all data: events, widget snapshot, progress settings,
    /// export files and delivered milestone notifications.
    /// Returns false (and changes nothing else) if the events couldn't be erased.
    @discardableResult
    func resetAllData() async -> Bool {
        do { try await services.store.deleteAll() } catch {
            lastError = String(describing: error)
            return false
        }
        settings.resetData()
        Self.removeExports()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        pendingMilestone = nil
        lastManualEvent = nil
        await reload()
        return true
    }

    /// Background-counting self-test (SCREEN_SPECIFICATIONS §8, USER_FLOWS F2).
    enum SelfTestState: Equatable {
        case notRun
        case waiting(since: Date)
        case passed(Date)
        /// The test window passed without both automations running; names the failing step.
        case failed(reason: String)
    }

    /// Time allowed for both automations to run after the test starts.
    static let selfTestWindow: TimeInterval = 60

    var selfTestState: SelfTestState {
        _ = selfTestVersion
        if let passed = settings.selfTestPassedAt { return .passed(passed) }
        guard let started = settings.selfTestStartedAt else { return .notRun }
        guard Date.now.timeIntervalSince(started) > Self.selfTestWindow else { return .waiting(since: started) }
        let foldRan = (settings.lastShortcutFold ?? .distantPast) >= started
        let unfoldRan = (settings.lastShortcutUnfold ?? .distantPast) >= started
        switch (foldRan, unfoldRan) {
        case (false, false):
            return .failed(reason: "Neither automation ran. Check that you're on iOS 27.2 or later, that both automations exist, and that they use FoldPulse's actions.")
        case (false, true):
            return .failed(reason: "The “Closed” automation didn't run. Check it uses “Record Fold” and Run Immediately.")
        case (true, false):
            return .failed(reason: "The “Opened” automation didn't run. Check it uses “Record Unfold” and Run Immediately.")
        case (true, true):
            return .failed(reason: "The automations ran too late. Try again: close, wait a moment, then open.")
        }
    }

    /// When an automation last recorded anything.
    var lastAutomationRun: Date? {
        [settings.lastShortcutFold, settings.lastShortcutUnfold].compactMap { $0 }.max()
    }

    /// Background counting is considered set up once the self-test has passed.
    var backgroundCountingVerified: Bool { settings.selfTestPassedAt != nil }

    func startSelfTest() {
        settings.selfTestStartedAt = .now
        settings.selfTestPassedAt = nil
        selfTestVersion += 1
    }

    /// Passes when both automations ran after the test started, within the window.
    func checkSelfTest(now: Date = .now) {
        guard settings.selfTestPassedAt == nil, let started = settings.selfTestStartedAt,
              let fold = settings.lastShortcutFold, let unfold = settings.lastShortcutUnfold,
              fold >= started, unfold >= started,
              max(fold, unfold).timeIntervalSince(started) <= Self.selfTestWindow else {
            selfTestVersion += 1 // let views re-evaluate waiting → failed
            return
        }
        settings.selfTestPassedAt = now
        selfTestVersion += 1
    }

    /// Bumped when self-test settings change, so views refresh.
    private(set) var selfTestVersion = 0

    /// The milestone sheet was shown: never show this one again.
    func dismissMilestone() {
        pendingMilestone = nil
        settings.pendingMilestone = nil
    }

    private func apply(_ state: LoadedState) {
        dashboard = state.dashboard
        recentEvents = state.recentEvents
        lastError = nil
    }

    #if DEBUG
    /// Developer-only: inserts the Phase 2 sample week so the UI can be reviewed on device.
    func insertSampleData(now: Date = .now, timeZone: TimeZone = .current) async {
        let today = LocalDay(date: now, timeZone: timeZone)
        let perDay = [58, 77, 69, 81, 74, 73]
        let sources: [DetectionSource] = [.hinge, .hinge, .shortcut, .hinge, .shortcut, .manual]
        var events: [FoldEvent] = []
        for (offset, count) in perDay.enumerated() {
            let start = today.adding(days: offset - perDay.count).start(in: timeZone)
            for i in 0..<count {
                let t = start.addingTimeInterval(7 * 3600 + Double(i) * 600)
                events.append(FoldEvent(type: .unfold, source: sources[i % sources.count], timestamp: t, timeZone: timeZone))
                events.append(FoldEvent(type: .fold, source: sources[(i + 1) % sources.count], timestamp: t.addingTimeInterval(240), timeZone: timeZone))
            }
        }
        do { try await services.store.add(contentsOf: events, checkingDuplicates: false) } catch { lastError = String(describing: error) }
        await reload()
    }

    func deleteAllData() async {
        await resetAllData()
    }
    #endif
}
