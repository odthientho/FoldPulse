import Foundation
import Observation
import FoldPulseCore

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

    /// Feeds one reading. `state` nil = no hinge in this hierarchy right now.
    func observe(_ state: CoarseHingeState?, label: String) {
        liveState = state
        liveLabel = label
        if state != nil { onHingeSeen?() }
        deliver(detector.observe(state, at: now()))
        scheduleTick()
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

    /// Delivers edges strictly in order, one after another.
    private func deliver(_ edges: [HingeEdge]) {
        guard !edges.isEmpty, let onEdge else { return }
        let previous = delivery
        delivery = Task {
            await previous?.value
            for edge in edges { await onEdge(edge) }
        }
    }
}
