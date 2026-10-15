import OmacosCore
import SwiftUI

/// Panel colours and font. Defaults are Tokyo Night / CaskaydiaMono; `reload()` reads the current
/// theme's `~/.local/state/omacos/theme/panel.conf` and `~/.local/state/omacos/font` before every show.
enum Theme {
    static var bg = color(0x1a1b26)
    static var bgSelected = color(0x283457)
    static var fg = color(0xc0caf5)
    static var dim = color(0x565f89)
    static var accent = color(0x7aa2f7)
    static var border = color(0x3b4261)
    static var fontName = "CaskaydiaMono Nerd Font"

    static func font(_ size: CGFloat) -> Font { .custom(fontName, size: size) }

    static func reload() {
        if let f = ThemeConfig.fontName() { fontName = f }
        for (key, value) in ThemeConfig.colors() {
            let c = color(value)
            switch key {
            case "bg": bg = c
            case "bg_selected": bgSelected = c
            case "fg": fg = c
            case "dim": dim = c
            case "accent": accent = c
            case "border": border = c
            default: break
            }
        }
    }

    private static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}
