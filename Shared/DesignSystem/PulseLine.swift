import SwiftUI

/// The FoldPulse signature: a short ECG-like stroke (DESIGN_SYSTEM §1).
struct PulseLine: Shape {
    func path(in rect: CGRect) -> Path {
        // Normalised points from the brand mark (viewBox 120 × 24).
        let points: [(CGFloat, CGFloat)] = [(0, 12), (38, 12), (46, 3), (56, 21), (64, 8), (70, 12), (120, 12)]
        var path = Path()
        for (index, point) in points.enumerated() {
            let p = CGPoint(x: rect.minX + rect.width * point.0 / 120, y: rect.minY + rect.height * point.1 / 24)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        return path
    }
}

#Preview {
    PulseLine()
        .stroke(FPColor.accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        .frame(width: 120, height: 24)
        .padding()
}
