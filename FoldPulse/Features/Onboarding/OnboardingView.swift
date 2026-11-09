import SwiftUI

/// First-launch onboarding (SCREEN_SPECIFICATIONS §1). No permission prompts here.
struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                pageView(title: "Every Fold. Every Beat.",
                         text: "FoldPulse counts how often you fold and unfold your iPhone Duo, and turns it into simple, beautiful stats.",
                         symbol: "waveform.path.ecg").tag(0)
                pageView(title: "How counting works",
                         text: "Automatic: counted for you while FoldPulse is open.\nShortcut: optional — counted in the background by an automation you add.\nManual: you can always record or fix a fold by hand.\n\nEvery number shows where it came from.",
                         symbol: "list.bullet.rectangle").tag(1)
                pageView(title: "Private by design",
                         text: "Your data stays on this iPhone. No account, no cloud, no tracking. Export your history any time.",
                         symbol: "lock.shield").tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            Button(page < 2 ? "Continue" : "Start counting") {
                if page < 2 { withAnimation { page += 1 } } else { onFinish() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
            .padding()
        }
        .background(FPColor.background)
    }

    private func pageView(title: String, text: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: FPSpace.l) {
            Spacer()
            Image(systemName: symbol).font(.system(size: 56)).foregroundStyle(FPColor.accent).accessibilityHidden(true)
            Text(title).font(.largeTitle.weight(.bold))
            Text(text).font(.title3).foregroundStyle(FPColor.text2)
            Spacer()
        }
        .padding(.horizontal, FPSpace.xl)
        .accessibilityElement(children: .combine)
    }
}
