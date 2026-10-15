import Foundation

/// The Tabs of Notes (ADR 0004): every `*.md` directly in the notes folder. The order the user
/// dragged them into is remembered; files nobody has placed yet go to the end, by name.
public enum NotesLibrary {
    /// `saved` order first (only names that still exist), then new names alphabetically.
    public static func order(files: [String], saved: [String]) -> [String] {
        let present = Set(files)
        var seen = Set<String>()
        let kept = saved.filter { present.contains($0) && seen.insert($0).inserted }
        let fresh = files.filter { !seen.contains($0) }.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        return kept + fresh
    }

    /// Tab names in a folder: `*.md` files, no hidden files, no subfolders.
    public static func names(in folder: URL, fileManager: FileManager = .default) -> [String] {
        let items = (try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])) ?? []
        return items.compactMap { url in
            guard url.pathExtension == "md",
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else { return nil }
            return url.deletingPathExtension().lastPathComponent
        }
    }

    /// A typed Tab name made safe as a file name: trimmed, no slashes or leading dots, no `.md`
    /// typed twice. nil when nothing usable is left.
    public static func sanitize(_ typed: String) -> String? {
        var name = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.lowercased().hasSuffix(".md") { name = String(name.dropLast(3)) }
        name = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        while name.hasPrefix(".") { name.removeFirst() }
        name = name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    /// The heading Cmd+Shift+D inserts, same shape as the old nvim pad's stamps.
    public static func timestamp(_ date: Date = Date(), locale: Locale = Locale(identifier: "en_US_POSIX")) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.dateFormat = "EEE dd MMM yyyy HH:mm"
        return "## " + f.string(from: date)
    }
}

/// ~/.local/state/omacos/notes.json — what Notes remembers between runs.
public struct NotesState: Codable, Equatable {
    public var order: [String] = []
    public var current: String?
    public var width: Double = 520
    public var height: Double = 420
    /// background opacity with and without focus, 0…1
    public var focusedOpacity: Double = 0.85
    public var unfocusedOpacity: Double = 0.2
    public var fontSize: Double = 14

    public init() {}

    // every key optional, so a state file from an older build still loads
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = NotesState()
        order = try c.decodeIfPresent([String].self, forKey: .order) ?? d.order
        current = try c.decodeIfPresent(String.self, forKey: .current)
        width = try c.decodeIfPresent(Double.self, forKey: .width) ?? d.width
        height = try c.decodeIfPresent(Double.self, forKey: .height) ?? d.height
        focusedOpacity = try c.decodeIfPresent(Double.self, forKey: .focusedOpacity) ?? d.focusedOpacity
        unfocusedOpacity = try c.decodeIfPresent(Double.self, forKey: .unfocusedOpacity) ?? d.unfocusedOpacity
        fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? d.fontSize
    }

    public static func load(from url: URL) -> NotesState {
        guard let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(NotesState.self, from: data) else { return NotesState() }
        return state
    }

    public func save(to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? encoder.encode(self).write(to: url, options: .atomic)
    }

    /// Cmd+Plus/Minus: 10 % steps, never fully invisible, never above opaque.
    public static func step(_ value: Double, by delta: Double) -> Double {
        min(1, max(0.05, ((value + delta) * 100).rounded() / 100))
    }
}
