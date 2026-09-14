import AppKit
import OmacosCore

enum RowIcon {
    case glyph(String)
    case image(NSImage)
}

enum RowAction {
    case app(AppItem)
    case launcherAction(LauncherAction)
    case entry(MenuEntry)
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

    private var apps: [AppItem] = []
    private var history = LaunchHistory()
    private var menu: MenuFile?
    private var level: [ResolvedEntry] = []
    private var levelGeneration = 0
    private var iconCache: [String: NSImage] = [:]
    /// the menu level the launcher was opened from (Backspace returns there)
    private var launcherParent: [String]?

    var prompt: String {
        switch mode {
        case .launcher(let uninstall): return uninstall ? "\u{F05E9}  uninstall" : "\u{F003B}"
        case .menu(let path): return "\u{F0493}  " + (path.last ?? "omacos")
        }
    }

    var footer: String {
        switch mode {
        case .launcher(let uninstall):
            return uninstall ? "enter  uninstall (Pearcleaner)  ·  backspace  back  ·  esc  close"
                             : "enter  launch  ·  ctrl-x  uninstall  ·  backspace  back  ·  esc  close"
        case .menu: return "enter  select  ·  backspace  back  ·  esc  close"
        }
    }

    // MARK: opening

    func open(_ newMode: Mode, from parent: [String]? = nil) {
        mode = newMode
        query = ""
        selected = 0
        launcherParent = parent
        reload()
    }

    func reload() {
        switch mode {
        case .launcher:
            apps = AppScanner.scan()
            history = LaunchHistory(text: (try? String(contentsOf: historyURL, encoding: .utf8)) ?? "")
            refilter()
        case .menu(let path):
            menu = try? MenuFile.load(from: menuURL)
            let entries = menu?.level(at: path) ?? []
            level = entries.map { ResolvedEntry(entry: $0, label: $0.label) }
            refilter()
            guard entries.contains(where: { $0.state != nil || $0.when != nil }) else { return }
            levelGeneration += 1
            let generation = levelGeneration
            DispatchQueue.global(qos: .userInitiated).async {
                let resolved = entries.resolved(with: SystemShell())
                DispatchQueue.main.async { [weak self] in
                    guard let self, generation == self.levelGeneration else { return }
                    self.level = resolved
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
        case .launcher:
            if let parent = launcherParent { open(.menu(path: parent)); return .keepOpen }
            return .hide
        case .menu(let path):
            if path.isEmpty { return .hide }
            open(.menu(path: Array(path.dropLast())))
            return .keepOpen
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
            // file order while nothing is typed, matched order otherwise
            let ranked = query.isEmpty ? level : Matcher.rank(level, query: query, label: { $0.label })
            rows = ranked.enumerated().map { i, r in Row(id: i, icon: .glyph(r.entry.icon), label: r.label, action: .entry(r.entry)) }
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
        case .entry(let entry):
            return activate(entry)
        }
    }

    /// ctrl-x in the launcher
    func secondary() -> Outcome {
        guard rows.indices.contains(selected), case .app(let app) = rows[selected].action else { return .keepOpen }
        return uninstallOutcome(app)
    }

    private func uninstallOutcome(_ app: AppItem) -> Outcome {
        var comps = URLComponents()
        comps.scheme = "pear"; comps.host = "uninstallApp"
        comps.queryItems = [URLQueryItem(name: "path", value: app.url.path)]
        guard let url = comps.url else { return .hide }
        return .hideThen { NSWorkspace.shared.open(url) }
    }

    private func activate(_ entry: MenuEntry) -> Outcome {
        guard case .menu(let path) = mode else { return .keepOpen }
        switch entry.kind {
        case .menu(let id, _):
            open(.menu(path: path + [id]))
            return .keepOpen
        case .view(let name, let args):
            if name == "launcher" {
                open(.launcher(uninstall: args.contains("--uninstall")), from: path)
                return .keepOpen
            }
            // views that still live in the Popup (issue #13)
            let request = args.isEmpty ? name : "\(name) \(args)"
            return .hideThen { SystemShell.detach("omacos-popup " + SystemShell.quoted(request)) }
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
