import SwiftUI

/// One-time milestone celebration (SCREEN_SPECIFICATIONS §11). No confetti, no streaks.
struct MilestoneSheet: View {
    let milestone: Int
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0

    var body: some View {
        VStack(spacing: FPSpace.l) {
            PulseLine()
                .trim(from: 0, to: reduceMotion ? 1 : drawn)
                .stroke(FPColor.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 220, height: 44)
                .accessibilityHidden(true)
            Text(milestone, format: .number)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(FPColor.pulseGradient)
                .minimumScaleFactor(0.5)
            Text("folds since install").font(.title3.weight(.semibold))
            Button("Nice") { onDone() }
                .buttonStyle(.borderedProminent)
                .controlSize(.extraLarge)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Milestone: \(milestone.formatted()) folds since install")
        .onAppear { withAnimation(.easeOut(duration: 1.2)) { drawn = 1 } }
        .presentationDetents([.medium])
    }
}
