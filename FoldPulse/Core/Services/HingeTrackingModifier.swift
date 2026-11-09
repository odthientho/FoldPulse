import SwiftUI
import FoldPulseCore

#if HINGE_API
/// Connects SwiftUI's hinge API (iOS 27.1, iPhone Duo) to the HingeTracker.
/// Compiled only when `HINGE_API` is set (DECISIONS T-10): CI runners don't have
/// the iOS 27.1 SDK yet. The API form matches FoldProbe, which compiled and ran
/// on the Founder's iPhone Duo (SPIKE_RESULTS). All logic lives in HingeTracker,
/// which CI tests; this file only converts the system type to `HingeReading`.
struct HingeTrackingModifier: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onHingeChange { _, newContext in
                // Only the foreground-active scene may count (feasibility §5, review E3).
                guard scenePhase == .active else { return }
                model.hinge.receive(Self.reading(newContext.hinge))
            }
            .onChange(of: scenePhase) { old, phase in
                if old == .active {
                    // Closing the phone may background the app before the debounce elapses.
                    model.hinge.flush()
                }
                if phase == .active || phase == .background {
                    model.hinge.resetBaseline()
                }
            }
    }

    static func reading(_ hinge: DeviceHinge?) -> HingeReading {
        guard let hinge else { return .unavailable }
        if hinge.status == .closed { return .closed }
        if hinge.status == .partiallyOpen { return .partiallyOpen }
        if hinge.status == .fullyOpen { return .fullyOpen }
        return .unknown
    }
}
#endif

extension View {
    /// Automatic fold counting while this view is on screen (no-op without HINGE_API).
    @ViewBuilder
    func hingeTracking() -> some View {
        #if HINGE_API
        modifier(HingeTrackingModifier())
        #else
        self
        #endif
    }
}
