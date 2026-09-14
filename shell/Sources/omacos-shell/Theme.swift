import SwiftUI

/// Panel colours. Defaults are Tokyo Night; `reload()` reads the current theme's
/// `~/.local/state/omacos/theme/panel.conf` (rendered by `omacos-theme set`) before every show.
enum Theme {
    static var bg = color(0x1a1b26)
    static var bgSelected = color(0x283457)
    static var fg = color(0xc0caf5)
    static var dim = color(0x565f89)
    static var accent = color(0x7aa2f7)
    static var border = color(0x3b4261)
    static let fontName = "CaskaydiaMono Nerd Font"

    static func font(_ size: CGFloat) -> Font { .custom(fontName, size: size) }

    static let confPath = NSString(string: "~/.local/state/omacos/theme/panel.conf").expandingTildeInPath

    static func reload() {
        guard let text = try? String(contentsOfFile: confPath, encoding: .utf8) else { return }
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, let c = color(hex: parts[1]) else { continue }
            switch parts[0] {
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

    private static func color(hex: String) -> Color? {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        return color(v)
    }

    private static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255)
    }
}
