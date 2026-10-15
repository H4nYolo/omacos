import Foundation

/// The current theme as `omacos-theme set` renders it for native windows: `key=#rrggbb` lines in
/// `~/.local/state/omacos/theme/panel.conf` (bg, bg_selected, fg, dim, accent, border) and the
/// font family in `~/.local/state/omacos/font`. Shared by the Panel and Notes.
public enum ThemeConfig {
    public static let confPath = NSString(string: "~/.local/state/omacos/theme/panel.conf").expandingTildeInPath
    public static let fontPath = NSString(string: "~/.local/state/omacos/font").expandingTildeInPath

    /// key → 0xRRGGBB
    public static func colors(_ text: String) -> [String: UInt32] {
        var out: [String: UInt32] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            var hex = parts[1]
            if hex.hasPrefix("#") { hex.removeFirst() }
            guard hex.count == 6, let value = UInt32(hex, radix: 16) else { continue }
            out[parts[0]] = value
        }
        return out
    }

    public static func colors() -> [String: UInt32] {
        (try? String(contentsOfFile: confPath, encoding: .utf8)).map(colors) ?? [:]
    }

    public static func fontName() -> String? {
        guard let name = try? String(contentsOfFile: fontPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else { return nil }
        return name
    }
}
