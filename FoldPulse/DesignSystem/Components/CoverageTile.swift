import SwiftUI
import FoldPulseCore

/// "Counted for you · N% of recorded folds" (Phase 2 review I-19: no verdict word,
/// and the denominator is explicitly *recorded* folds).
struct CoverageTile: View {
    let coverage: Coverage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Counted for you · this week").font(FPFont.label).foregroundStyle(FPColor.text2)
            if let share = coverage.countedForYouShare {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(share, format: .percent.precision(.fractionLength(0)))
                        .font(FPFont.tileNumeral)
                        .foregroundStyle(color(for: share))
                    Text("of recorded folds").font(FPFont.caption).foregroundStyle(FPColor.text2)
                }
                Text("Automatic \(coverage.hinge) · Shortcut \(coverage.shortcut) · Manual \(coverage.manual)"
                     + (coverage.gaps > 0 ? " · \(coverage.gaps) gaps" : ""))
                    .font(FPFont.caption)
                    .foregroundStyle(FPColor.text2)
            } else {
                Text("No folds recorded this week yet").font(FPFont.caption).foregroundStyle(FPColor.text2)
            }
        }
        .fpCard(radius: FPRadius.tile)
        .accessibilityElement(children: .combine)
    }

    private func color(for share: Double) -> Color {
        switch share {
        case 0.9...: return FPColor.positive
        case 0.7..<0.9: return FPColor.text
        default: return FPColor.warning
        }
    }
}
