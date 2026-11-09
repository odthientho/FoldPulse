import Foundation
import Observation
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
            lastError = String(describing: error)
        }
        await reload()
    }

    func edit(_ event: FoldEvent) async {
        do {
            try await services.store.edit(event, now: .now)
        } catch {
            lastError = String(describing: error)
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
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Export", isDirectory: true)
        try? FileManager.default.removeItem(at: directory) // never leave older exports behind
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("FoldPulse-\(day).\(format.rawValue.lowercased())")
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    /// Settings → Reset all data: events, snapshot-backed widget and progress settings.
    func resetAllData() async {
        do { try await services.store.deleteAll() } catch { lastError = String(describing: error) }
        settings.resetData()
        pendingMilestone = nil
        lastManualEvent = nil
        await reload()
    }

    /// Background-counting self-test (SCREEN_SPECIFICATIONS §8).
    enum SelfTestState: Equatable {
        case notRun, waiting(since: Date), passed(Date)
    }

    var selfTestState: SelfTestState {
        if let passed = settings.selfTestPassedAt { return .passed(passed) }
        if let started = settings.selfTestStartedAt { return .waiting(since: started) }
        return .notRun
    }

    func startSelfTest() {
        settings.selfTestStartedAt = .now
        settings.selfTestPassedAt = nil
        selfTestVersion += 1
    }

    /// Passes when both automations ran after the test started (within 10 minutes).
    func checkSelfTest() {
        guard let started = settings.selfTestStartedAt,
              let fold = settings.lastShortcutFold, let unfold = settings.lastShortcutUnfold,
              fold >= started, unfold >= started, Date.now.timeIntervalSince(started) < 600 else { return }
        settings.selfTestPassedAt = .now
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
        do { try await services.store.add(contentsOf: events) } catch { lastError = String(describing: error) }
        await reload()
    }

    func deleteAllData() async {
        await resetAllData()
    }
    #endif
}
