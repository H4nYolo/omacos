import AppKit

struct AppItem: Equatable {
    let name: String
    let url: URL
}

/// Same sources as omacos-launcher: every place macOS keeps apps, deduplicated by name.
enum AppScanner {
    static let directories = [
        "/Applications", "/Applications/Utilities",
        NSHomeDirectory() + "/Applications",
        "/System/Applications", "/System/Applications/Utilities",
        "/System/Library/CoreServices/Applications",
    ]

    static func scan() -> [AppItem] {
        var seen = Set<String>()
        var apps: [AppItem] = []
        let fm = FileManager.default
        for dir in directories {
            guard let names = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for file in names.sorted() where file.hasSuffix(".app") && !file.hasPrefix(".") {
                let name = String(file.dropLast(4))
                if seen.insert(name).inserted {
                    apps.append(AppItem(name: name, url: URL(fileURLWithPath: dir).appendingPathComponent(file)))
                }
            }
        }
        if seen.insert("Finder").inserted {
            apps.append(AppItem(name: "Finder", url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")))
        }
        return apps.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}

/// The launcher's extra entries (Omarchy menu → System), same names as in omacos-launcher.
struct LauncherAction {
    let name: String
    let glyph: String
    let command: String

    static let all = [
        LauncherAction(name: "Screensaver", glyph: "\u{F04B2}", command: "omacos-screensaver"),
        LauncherAction(name: "Lock screen", glyph: "\u{F033E}", command: "omacos-system lock"),
        LauncherAction(name: "Sleep", glyph: "\u{F0904}", command: "omacos-system sleep"),
    ]
}
