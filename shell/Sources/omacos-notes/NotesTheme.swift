import AppKit
import OmacosCore

/// Notes' colours and fonts from the current omacos theme (Tokyo Night / CaskaydiaMono until
/// `reload()` finds the rendered files). `omacos-theme set` and `omacos-font set` send `reload`.
enum NotesTheme {
    static var bg = color(0x1a1b26)
    static var bgSelected = color(0x283457)
    static var fg = color(0xc0caf5)
    static var dim = color(0x565f89)
    static var accent = color(0x7aa2f7)
    static var border = color(0x3b4261)
    static var fontName = "CaskaydiaMono Nerd Font"

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

    static func font(_ size: CGFloat, bold: Bool = false, italic: Bool = false) -> NSFont {
        var font = NSFont(name: fontName, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        let manager = NSFontManager.shared
        if bold { font = manager.convert(font, toHaveTrait: .boldFontMask) }
        if italic { font = manager.convert(font, toHaveTrait: .italicFontMask) }
        return font
    }

    private static func color(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }
}
