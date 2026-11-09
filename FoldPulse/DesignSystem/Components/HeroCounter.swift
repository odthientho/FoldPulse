import SwiftUI

/// "Folds since install" + hero numeral + pulse line (DESIGN_SYSTEM §6).
struct HeroCounter: View {
    let label: String
    let value: Int
    /// Upper bound for the scaled numeral so 6 digits fit the 5.4" display at AX sizes.
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: FPSpace.xs) {
            Text(label)
                .font(FPFont.label)
                .foregroundStyle(FPColor.text2)
            Text(value, format: .number)
                .font(.system(size: min(size, 96), weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(FPColor.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)
            PulseLine()
                .stroke(FPColor.accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                .frame(width: 120, height: 24)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value == 1 ? "1 fold since install" : "\(value.formatted()) \(label.lowercased())")
        .accessibilityIdentifier("heroCounter")
    }
}

#Preview {
    HeroCounter(label: "Folds since install", value: 1_284).padding()
}
