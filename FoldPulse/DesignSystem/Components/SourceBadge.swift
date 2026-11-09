import SwiftUI
import FoldPulseCore

/// Symbol + label for an event source. Colour is never the only signal.
struct SourceBadge: View {
    let source: DetectionSource
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: source.symbolName)
            if !compact { Text(source.label) }
        }
        .font(FPFont.badge)
        .foregroundStyle(source.color)
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 3)
        .background {
            if source == .inferred {
                RoundedRectangle(cornerRadius: FPRadius.badge, style: .continuous)
                    .strokeBorder(source.color, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            } else {
                RoundedRectangle(cornerRadius: FPRadius.badge, style: .continuous).fill(source.color.opacity(0.14))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(source.label)
    }
}

extension DetectionSource {
    var label: String {
        switch self {
        case .hinge: return "Automatic"
        case .shortcut: return "Shortcut"
        case .manual: return "Manual"
        case .inferred: return "Gap"
        }
    }

    var symbolName: String {
        switch self {
        case .hinge: return "waveform.path.ecg"
        case .shortcut: return "square.2.layers.3d"
        case .manual: return "hand.tap"
        case .inferred: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .hinge: return FPColor.accentText
        case .shortcut: return FPColor.sourceShortcut
        case .manual: return FPColor.sourceManual
        case .inferred: return FPColor.text2
        }
    }
}

#Preview {
    VStack { ForEach(DetectionSource.allCases, id: \.self) { SourceBadge(source: $0) } }.padding()
}
