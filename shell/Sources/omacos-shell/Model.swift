import AppKit
import OmacosCore

enum RowIcon {
    case glyph(String)
    case image(NSImage)
    case none
}

enum RowAction {
    case app(AppItem)
    case launcherAction(LauncherAction)
    /// a Menu entry and the level it lives in (deep search shows entries below the opened level)
    case entry(MenuEntry, path: [String])
    case emoji(String)
    case clip(URL)
    case text
}

struct Row: Identifiable {
    let id: Int
    let icon: RowIcon
    let label: String
    let action: RowAction
}

/// What a key press leads to, decided by the model, executed by the controller.
enum Outcome {
    case keepOpen
    case hide
    case hideThen(() -> Void)
}

@MainActor
final class PanelModel: ObservableObject {
    enum Mode: Equatable {
        case launcher(uninstall: Bool)
        case menu(path: [String])
        case emoji
        case clipboard
        case keys(section: String)

        /// panel size per view: the wide ones carry a preview or long lines
        var size: NSSize {
            switch self {
            case .clipboard, .keys: return NSSize(width: 980, height: 520)
            default: return NSSize(width: 720, height: 480)
            }
        }
        var hasPreview: Bool { if case .clipboard = self { return true } else { return false } }
    }

    @Published var mode: Mode = .launcher(uninstall: false)
    @Published var query = ""
    @Published var rows: [Row] = []
    @Published var selected = 0

    /// set by the controller: a row was clicked
    var activateRequested: (() -> Void)?

    private let home = NSHomeDirectory()
    private var menuURL: URL { URL(fileURLWithPath: home + "/.config/omacos/menu.json") }
    private var historyURL: URL { URL(fileURLWithPath: home + "/.local/state/omacos/launcher-history") }
    private var emojiURL: URL { URL(fileURLWithPath: home + "/.config/omacos/emoji.tsv") }
    private var clipboardDir: URL { URL(fileURLWithPath: home + "/.local/state/omacos/clipboard") }

    private var apps: [AppItem] = []
    private var history = LaunchHistory()
    private var menu: MenuFile?
    /// the opened level and everything below it (depth 0 = the level itself), breadcrumb labels
    private var tree: [ResolvedEntry] = []
    private var levelGeneration = 0
    private var iconCache: [String: NSImage] = [:]
    private var emojis: [EmojiEntry] = []
    private var clips: [URL] = []
    private var keyLines: [String] = []
    /// the menu level a view was opened from (Backspace returns there)
    private var parent: [String]?

    /// full text of the selected clipboard entry (clipboard view only)
    var preview: String {
        guard case .clipboard = mode, rows.indices.contains(selected), case .clip(let url) = rows[selected].action,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "" }
        return String(text.prefix(20_000))
    }

    var prompt: String {
        switch mode {
        case .launcher(let uninstall): return uninstall ? "\u{F05E9}  uninstall" : "\u{F003B}"
        case .menu(let path): return "\u{F0493}  " + (path.last ?? "omacos")
        case .emoji: return "\u{F0785}"
        case .clipboard: return "\u{F018F}"
        case .keys(let section): return "\u{F030C}  " + (section == "all" ? "keys" : section)
        }
    }

    var footer: String {
        switch mode {
        case .launcher(let uninstall):
            return uninstall ? "enter  uninstall (Pearcleaner)  ·  backspace  back  ·  esc  close"
                             : "enter  launch  ·  ctrl-x  uninstall  ·  backspace  back  ·  esc  close"
        case .menu: return "enter  select  ·  backspace  back  ·  esc  close"
        case .emoji: return "enter  paste  ·  backspace  back  ·  esc  close"
        case .clipboard: return "enter  paste  ·  ctrl-x  delete  ·  alt-c  clear all  ·  backspace  back  ·  esc  close"
        case .keys: return "type to search  ·  backspace  back  ·  esc  close"
        }
    }

    // MARK: opening

    func open(_ newMode: Mode, from parent: [String]? = nil) {
        mode = newMode
        query = ""
        selected = 0
        self.parent = parent
        reload()
    }

    func reload() {
        switch mode {
        case .launcher:
            apps = AppScanner.scan()
            history = LaunchHistory(text: (try? String(contentsOf: historyURL, encoding: .utf8)) ?? "")
            refilter()
        case .emoji:
            if emojis.isEmpty { emojis = EmojiTable.parse((try? String(contentsOf: emojiURL, encoding: .utf8)) ?? "") }
            refilter()
        case .clipboard:
            let fm = FileManager.default
            let urls = (try? fm.contentsOfDirectory(at: clipboardDir, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
            clips = urls.sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return da > db
            }
            refilter()
        case .keys(let section):
            let out = SystemShell().run("omacos-keys \(section == "all" ? "" : section) --list").output
            keyLines = out.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
            refilter()
        case .menu(let path):
            menu = try? MenuFile.load(from: menuURL)
            let entries = menu?.descendants(below: path) ?? []
            tree = entries
            refilter()
            guard entries.contains(where: { $0.entry.state != nil || $0.entry.when != nil }) else { return }
            levelGeneration += 1
            let generation = levelGeneration
            DispatchQueue.global(qos: .userInitiated).async {
                let resolved = entries.resolved(with: SystemShell())
                DispatchQueue.main.async { [weak self] in
                    guard let self, generation == self.levelGeneration else { return }
                    self.tree = resolved
                    self.refilter()
                }
            }
        }
    }

    // MARK: query

    func append(_ text: String) { query += text; selected = 0; refilter() }

    /// Backspace: shorten the query, or go one level up when it is empty.
    func backspace() -> Outcome {
        if !query.isEmpty {
            query.removeLast(); selected = 0; refilter()
            return .keepOpen
        }
        switch mode {
        case .menu(let path):
            if path.isEmpty { return .hide }
            open(.menu(path: Array(path.dropLast())))
            return .keepOpen
        default:
            if let parent { open(.menu(path: parent)); return .keepOpen }
            return .hide
        }
    }

    func moveSelection(by delta: Int) {
        guard !rows.isEmpty else { return }
        selected = (selected + delta + rows.count) % rows.count
    }

    func refilter() {
        switch mode {
        case .launcher:
            let ranked = Matcher.rank(launcherItems(), query: query, label: { $0.label }, rank: { history.count($0.label) })
            rows = ranked.enumerated().map { i, item in Row(id: i, icon: item.icon, label: item.label, action: item.action) }
        case .menu:
            // the level in file order while nothing is typed; typing searches the whole tree below
            // it, matched order, entries of the level itself ahead of deeper ones on equal scores
            let ranked = query.isEmpty ? tree.filter { $0.depth == 0 }
                                       : Matcher.rank(tree, query: query, label: { $0.label }, rank: { -$0.depth })
            rows = ranked.enumerated().map { i, r in Row(id: i, icon: .glyph(r.entry.icon), label: r.label, action: .entry(r.entry, path: r.path)) }
        case .emoji:
            let ranked = query.isEmpty ? emojis : Matcher.rank(emojis, query: query, label: { $0.searchText })
            rows = ranked.prefix(400).enumerated().map { i, e in Row(id: i, icon: .glyph(e.emoji), label: e.name, action: .emoji(e.emoji)) }
        case .clipboard:
            let items = clips.map { url -> (URL, String) in
                let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                let line = text.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\t", with: " ")
                return (url, String(line.prefix(140)))
            }
            let ranked = query.isEmpty ? items : Matcher.rank(items, query: query, label: { $0.1 })
            rows = ranked.enumerated().map { i, c in Row(id: i, icon: .none, label: c.1, action: .clip(c.0)) }
        case .keys:
            let ranked = query.isEmpty ? keyLines : Matcher.rank(keyLines, query: query, label: { $0 })
            rows = ranked.enumerated().map { i, l in Row(id: i, icon: .none, label: l, action: .text) }
        }
        if selected >= rows.count { selected = max(rows.count - 1, 0) }
    }

    private struct LauncherItem { let label: String; let icon: RowIcon; let action: RowAction }

    private func launcherItems() -> [LauncherItem] {
        var items = apps.map { app in LauncherItem(label: app.name, icon: .image(icon(for: app)), action: .app(app)) }
        if case .launcher(let uninstall) = mode, !uninstall {
            items += LauncherAction.all.map { LauncherItem(label: $0.name, icon: .glyph($0.glyph), action: .launcherAction($0)) }
        }
        return items
    }

    private func icon(for app: AppItem) -> NSImage {
        if let cached = iconCache[app.url.path] { return cached }
        let image = NSWorkspace.shared.icon(forFile: app.url.path)
        image.size = NSSize(width: 20, height: 20)
        iconCache[app.url.path] = image
        return image
    }

    // MARK: actions

    /// Enter
    func activate() -> Outcome {
        guard rows.indices.contains(selected) else { return .keepOpen }
        let row = rows[selected]
        switch row.action {
        case .app(let app):
            if case .launcher(let uninstall) = mode, uninstall { return uninstallOutcome(app) }
            bump(row.label)
            return .hideThen { NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration()) }
        case .launcherAction(let action):
            bump(row.label)
            return .hideThen { SystemShell.detach(action.command) }
        case .entry(let entry, let path):
            return activate(entry, at: path)
        case .emoji(let emoji):
            return .hideThen { Self.pasteboard(emoji); SystemShell.detach("sleep 0.15; omacos-paste") }
        case .clip(let url):
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return .keepOpen }
            return .hideThen { Self.pasteboard(text); SystemShell.detach("sleep 0.15; omacos-paste") }
        case .text:
            return .hide
        }
    }

    /// ctrl-x: uninstall in the launcher, delete in the clipboard
    func secondary() -> Outcome {
        guard rows.indices.contains(selected) else { return .keepOpen }
        switch rows[selected].action {
        case .app(let app): return uninstallOutcome(app)
        case .clip(let url):
            try? FileManager.default.removeItem(at: url)
            reload()
            return .keepOpen
        default: return .keepOpen
        }
    }

    /// alt-c in the clipboard: clear the history
    func clearAll() -> Outcome {
        guard case .clipboard = mode else { return .keepOpen }
        for url in clips { try? FileManager.default.removeItem(at: url) }
        reload()
        return .keepOpen
    }

    private static func pasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    private func uninstallOutcome(_ app: AppItem) -> Outcome {
        var comps = URLComponents()
        comps.scheme = "pear"; comps.host = "uninstallApp"
        comps.queryItems = [URLQueryItem(name: "path", value: app.url.path)]
        guard let url = comps.url else { return .hide }
        return .hideThen { NSWorkspace.shared.open(url) }
    }

    /// `path` is the level the entry lives in: a submenu opens below it, a view returns there on Backspace.
    private func activate(_ entry: MenuEntry, at path: [String]) -> Outcome {
        guard case .menu = mode else { return .keepOpen }
        switch entry.kind {
        case .menu(let id, _):
            open(.menu(path: path + [id]))
            return .keepOpen
        case .view(let name, let args):
            switch name {
            case "launcher": open(.launcher(uninstall: args.contains("--uninstall")), from: path)
            case "emoji": open(.emoji, from: path)
            case "clipboard": open(.clipboard, from: path)
            case "keys": open(.keys(section: args.isEmpty ? "all" : args), from: path)
            default:
                let request = args.isEmpty ? name : "\(name) \(args)"
                return .hideThen { SystemShell.detach("omacos-popup " + SystemShell.quoted(request)) }
            }
            return .keepOpen
        case .popup(let name):
            return .hideThen { SystemShell.detach("omacos-popup " + SystemShell.quoted(name)) }
        case .run(let command):
            return .hideThen { SystemShell.detach(command) }
        }
    }

    private func bump(_ name: String) {
        history.bump(name)
        let dir = historyURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? history.text.write(to: historyURL, atomically: true, encoding: .utf8)
    }
}
