import SwiftUI

/// Tokyo Night, one place. The theme switcher (issue #5) will feed this later.
enum Theme {
    static let bg = color(0x1a1b26)
    static let bgSelected = color(0x283457)
    static let fg = color(0xc0caf5)
    static let dim = color(0x565f89)
    static let accent = color(0x7aa2f7)
    static let border = color(0x3b4261)
    static let fontName = "CaskaydiaMono Nerd Font"

    static func font(_ size: CGFloat) -> Font { .custom(fontName, size: size) }

    private static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}
