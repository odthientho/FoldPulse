import SwiftUI

/// Type roles from DESIGN_SYSTEM §4. SF Pro (system) with Dynamic Type.
enum FPFont {
    static let tileNumeral = Font.system(.title, design: .rounded).weight(.bold).monospacedDigit()
    static let label = Font.subheadline
    static let caption = Font.footnote
    static let badge = Font.caption.weight(.semibold)
}

extension View {
    /// Standard card surface.
    func fpCard(radius: CGFloat = FPRadius.card) -> some View {
        padding(FPSpace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FPColor.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
