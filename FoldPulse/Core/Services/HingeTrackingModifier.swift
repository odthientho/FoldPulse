import SwiftUI
import FoldPulseCore

#if HINGE_API
/// Connects SwiftUI's hinge API (iOS 27.1, iPhone Duo) to the HingeTracker.
/// Compiled only when `HINGE_API` is set (DECISIONS T-10): CI runners don't have
/// the iOS 27.1 SDK yet. The API form matches FoldProbe, which compiled and ran
/// on the Founder's iPhone Duo (SPIKE_RESULTS).
struct HingeTrackingModifier: ViewModifier {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onHingeChange { _, newContext in
                guard let hinge = newContext.hinge else {
                    model.hinge.observe(nil, label: "No hinge reading")
                    return
                }
                let status = hinge.status
                if status == .closed {
                    model.hinge.observe(.closed, label: "Closed")
                } else if status == .partiallyOpen {
                    model.hinge.observe(.open, label: "Partially open")
                } else if status == .fullyOpen {
                    model.hinge.observe(.open, label: "Fully open")
                } else {
                    model.hinge.observe(nil, label: "Unknown")
                }
            }
            .onChange(of: scenePhase) { _, _ in
                // Closing the phone may background the app before the debounce elapses.
                model.hinge.flush()
            }
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
