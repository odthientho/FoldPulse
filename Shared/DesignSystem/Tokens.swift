import SwiftUI
import UIKit

/// Design tokens from docs/DESIGN_SYSTEM.md §3 (contrast measured with
/// design/contrast_check.py — all text pairs pass WCAG AA).
enum FPColor {
    static let background = Color(light: 0xF2F4F8, dark: 0x070F1F)
    static let surface = Color(light: 0xFFFFFF, dark: 0x12233F)
    static let text = Color(light: 0x0B1B33, dark: 0xFFFFFF)
    static let text2 = Color(light: 0x55606E, dark: 0x9FB1CF)
    /// Graphics, fills and large text only (≥ 3:1).
    static let accent = Color(light: 0x2F7BFF, dark: 0x4C8DFF)
    /// Accent-coloured small text and links (≥ 4.5:1).
    static let accentText = Color(light: 0x1D5FD8, dark: 0x6FA2FF)
    static let signalCyan = Color(light: 0x5CC8FF, dark: 0x5CC8FF)
    static let sourceShortcut = Color(light: 0x0B6F85, dark: 0x5CC8FF)
    static let sourceManual = Color(light: 0x55606E, dark: 0xB4C0D3)
    static let positive = Color(light: 0x1E7F4F, dark: 0x5BD08E)
    static let warning = Color(light: 0xA15C00, dark: 0xFFB547)
    static let destructive = Color(light: 0xC2362B, dark: 0xFF6B5E)
    static let chip = Color(light: 0xE8ECF3, dark: 0x1A2E50)

    static var pulseGradient: LinearGradient { LinearGradient(colors: [accent, signalCyan], startPoint: .leading, endPoint: .trailing) }
}

/// Spacing scale (4-pt grid) and corner radii (DESIGN_SYSTEM §5).
enum FPSpace {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum FPRadius {
    static let card: CGFloat = 20
    static let tile: CGFloat = 16
    static let badge: CGFloat = 8
}

extension Color {
    /// A colour that adapts to light/dark mode, from 0xRRGGBB values.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}
