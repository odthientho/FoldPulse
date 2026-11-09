import Foundation
import Observation
import UIKit
import FoldPulseCore

/// A hinge reading, independent of the iOS 27.1 types so the mapping is testable in CI.
enum HingeReading: Equatable, Sendable {
    case closed, partiallyOpen, fullyOpen
    /// The system reported a status FoldPulse doesn't recognise.
    case unknown
    /// No hinge in this view hierarchy right now (e.g. the scene left the screen).
    case unavailable

    var label: String {
        switch self {
        case .closed: return "Closed"
        case .partiallyOpen: return "Partially open"
        case .fullyOpen: return "Fully open"
        case .unknown: return "Unknown"
        case .unavailable: return "No hinge reading"
        }
    }
}

/// Automatic counting while FoldPulse is on screen (F1).
///
/// Receives coarse hinge readings (from `onHingeChange`, see HingeTrackingModifier),
/// runs them through `HingeEdgeDetector` (debounce, baseline, flush) and delivers
/// committed edges, in order, to `onEdge`. One instance per process, owned by AppModel.
@MainActor
@Observable
final class HingeTracker {
    /// Latest reading, for the Record sheet's "Hinge right now".
    private(set) var liveState: CoarseHingeState?
    private(set) var liveLabel = "Waiting for hinge…"

    @ObservationIgnored var onEdge: (@MainActor (HingeEdge) async -> Void)?
    /// Called on every non-nil reading (persists "this device has a hinge").
    @ObservationIgnored var onHingeSeen: (@MainActor () -> Void)?

    @ObservationIgnored private var detector = HingeEdgeDetector()
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private var delivery: Task<Void, Never>?
    @ObservationIgnored private let now: @MainActor () -> Date

    init(now: @escaping @MainActor () -> Date = { Date.now }) {
        self.now = now
    }

    /// Feeds one reading (TECHNICAL_FEASIBILITY §6):
    /// - closed / partially open / fully open → the detector (partial and full are both "open");
    /// - unknown → label only: it must never change the baseline (Phase 4 review E2);
    /// - unavailable → resets the baseline: the next reading is a new baseline.
    func receive(_ reading: HingeReading) {
        liveLabel = reading.label
        let state: CoarseHingeState?
        switch reading {
        case .closed: state = .closed
        case .partiallyOpen, .fullyOpen: state = .open
        case .unknown: return
        case .unavailable: state = nil
        }
        liveState = state
        if state != nil { onHingeSeen?() }
        deliver(detector.observe(state, at: now()))
        scheduleTick()
    }

    /// Forgets the baseline (the app returned to the foreground, Phase 4 review E1):
    /// the first reading afterwards only sets a new baseline, so a fold made while the
    /// app was away (counted by the Shortcut, or missed) never becomes a phantom hinge fold.
    func resetBaseline() {
        tickTask?.cancel()
        detector.resetBaseline()
    }

    /// Commits a stable pending state (called by the debounce timer, or tests).
    func tick() {
        deliver(detector.tick(at: now()))
    }

    /// Commits any pending state immediately (scene phase change).
    func flush() {
        tickTask?.cancel()
        deliver(detector.flush())
    }

    /// Waits until all delivered edges have been processed (tests).
    func waitForDelivery() async {
        await delivery?.value
    }

    private func scheduleTick() {
        tickTask?.cancel()
        guard let deadline = detector.pendingDeadline else { return }
        let delay = max(0, deadline.timeIntervalSince(now())) + 0.02
        tickTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.tick()
        }
    }

    /// Delivers edges strictly in order, one after another. Each delivery asks iOS
    /// for background time, because a fold flushed as the phone closes is saved
    /// while the app is going to the background (Phase 4 review E4).
    private func deliver(_ edges: [HingeEdge]) {
        guard !edges.isEmpty, let onEdge else { return }
        let previous = delivery
        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "FoldPulse.saveFold")
        delivery = Task {
            await previous?.value
            for edge in edges { await onEdge(edge) }
            if backgroundTask != .invalid { UIApplication.shared.endBackgroundTask(backgroundTask) }
        }
    }
}
