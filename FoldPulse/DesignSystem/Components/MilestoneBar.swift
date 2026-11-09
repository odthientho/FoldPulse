import SwiftUI
import FoldPulseCore

/// Gradient progress toward the next milestone.
struct MilestoneBar: View {
    let total: Int

    var body: some View {
        if let next = Milestones.next(after: total), let progress = Milestones.progress(total: total) {
            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(FPColor.pulseGradient)
                Text("\((next - total).formatted()) to the \(next.formatted()) milestone")
                    .font(FPFont.caption)
                    .foregroundStyle(FPColor.text2)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
