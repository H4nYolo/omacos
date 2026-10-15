import AppKit
import OmacosCore

/// The Tabs and their files. The text view owns the live text of the current Tab; this keeps a
/// copy per Tab, writes it 0.5 s after the last change and picks up changes made outside
/// (nvim, git) once a second.
@MainActor
final class NotesModel: ObservableObject {
    enum Editing: Equatable { case new, rename(String) }

    struct Doc {
        var text: String
        var modified: Date?
        var dirty = false
        var selection = NSRange(location: 0, length: 0)
        let undo: UndoManager
    }

    struct Hit: Identifiable {
        let id: Int
        let tab: String
        let line: Int?        // nil = the Tab itself
        let label: String
    }

    @Published private(set) var tabs: [String] = []
    @Published private(set) var current: String?
    @Published var editing: Editing?
    @Published var notice: String?
    @Published var paletteOpen = false

    let folder: URL
    let stateURL = URL(fileURLWithPath: NSHomeDirectory() + "/.local/state/omacos/notes.json")
    var state: NotesState
    private var docs: [String: Doc] = [:]
    private var closed = Set<String>()     // Cmd+W: hidden until restart or Cmd+P
    private var saveTimer: Timer?
    private var pollTimer: Timer?

    /// the controller swaps the text view's contents
    var onSwitch: ((String) -> Void)?
    /// the current Tab's file changed outside and was reloaded
    var onReload: (() -> Void)?
    /// Cmd+T made a new Tab: start typing in it
    var onCreated: (() -> Void)?

    init() {
        let configured = (try? String(contentsOfFile: NSHomeDirectory() + "/.config/omacos/notes-dir", encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let path = (configured?.isEmpty == false ? configured! : "~/notes") as NSString
        folder = URL(fileURLWithPath: path.expandingTildeInPath, isDirectory: true)
        state = NotesState.load(from: stateURL)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if NotesLibrary.names(in: folder).isEmpty {
            try? "# Quick notes\n\n".write(to: url(of: "quick"), atomically: true, encoding: .utf8)
        }
        refresh()
        current = state.current.flatMap { tabs.contains($0) ? $0 : nil } ?? tabs.first
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func url(of tab: String) -> URL { folder.appendingPathComponent(tab + ".md") }

    func doc(_ tab: String) -> Doc? { docs[tab] }

    func undoManager(for tab: String?) -> UndoManager? { tab.flatMap { docs[$0]?.undo } }

    // MARK: files on disk

    private func modified(_ tab: String) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url(of: tab).path))?[.modificationDate] as? Date
    }

    /// New files become Tabs, deleted ones disappear, outside edits are loaded.
    func refresh() {
        let names = NotesLibrary.names(in: folder)
        let ordered = NotesLibrary.order(files: names, saved: state.order)
        if ordered != state.order { state.order = ordered; persist() }
        let visible = ordered.filter { !closed.contains($0) }
        if visible != tabs { tabs = visible }
        for name in docs.keys where !names.contains(name) { docs[name] = nil }

        for name in names {
            let date = modified(name)
            guard var doc = docs[name] else {
                if visible.contains(name) { docs[name] = Doc(text: read(name), modified: date, undo: UndoManager()) }
                continue
            }
            guard date != doc.modified else { continue }
            if doc.dirty {
                notice = "\(name) changed on disk — kept yours"
            } else {
                doc.text = read(name)
                doc.modified = date
                docs[name] = doc
                if name == current { onReload?() }
            }
        }
        if let c = current, !visible.contains(c) {
            current = nil
            if let first = visible.first { select(first) }
        }
    }

    private func read(_ tab: String) -> String {
        (try? String(contentsOf: url(of: tab), encoding: .utf8)) ?? ""
    }

    // MARK: editing

    func textChanged(_ text: String, selection: NSRange) {
        guard let c = current else { return }
        docs[c]?.text = text
        docs[c]?.selection = selection
        docs[c]?.dirty = true
        saveTimer?.invalidate()
        saveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.saveAll() }
        }
    }

    func selectionChanged(_ selection: NSRange) {
        if let c = current { docs[c]?.selection = selection }
    }

    func saveAll() {
        saveTimer?.invalidate()
        for (name, doc) in docs where doc.dirty {
            do {
                try doc.text.write(to: url(of: name), atomically: true, encoding: .utf8)
                docs[name]?.dirty = false
                docs[name]?.modified = modified(name)
            } catch {
                notice = "could not save \(name)"
            }
        }
    }

    // MARK: tabs

    func select(_ tab: String) {
        guard tab != current || docs[tab] == nil else { return }
        saveAll()
        closed.remove(tab)
        refresh()
        if docs[tab] == nil { docs[tab] = Doc(text: read(tab), modified: modified(tab), undo: UndoManager()) }
        current = tab
        state.current = tab
        persist()
        onSwitch?(tab)
    }

    func select(offset: Int) {
        guard let c = current, let i = tabs.firstIndex(of: c), !tabs.isEmpty else { return }
        select(tabs[(i + offset + tabs.count) % tabs.count])
    }

    func select(number: Int) {
        if number - 1 < tabs.count { select(tabs[number - 1]) }
    }

    func close(_ tab: String) {
        guard tabs.count > 1 else { notice = "the last Tab stays open"; return }
        if tab == current, let i = tabs.firstIndex(of: tab) {
            select(tabs[i + 1 < tabs.count ? i + 1 : i - 1])     // the neighbour takes over
        }
        closed.insert(tab)
        refresh()
    }

    /// Enter in the tab bar's name field: a new Tab or a rename.
    func commitEditing(_ typed: String) {
        defer { editing = nil }
        guard let name = NotesLibrary.sanitize(typed), let mode = editing else { return }
        let taken = FileManager.default.fileExists(atPath: url(of: name).path)
        switch mode {
        case .new:
            if !taken { try? "# \(name)\n\n".write(to: url(of: name), atomically: true, encoding: .utf8) }
            select(name)
            if !taken { onCreated?() }
        case .rename(let old):
            guard name != old else { return }
            guard !taken else { notice = "\(name) exists already"; return }
            saveAll()
            do {
                try FileManager.default.moveItem(at: url(of: old), to: url(of: name))
            } catch {
                notice = "could not rename \(old)"; return
            }
            docs[name] = docs.removeValue(forKey: old)
            state.order = state.order.map { $0 == old ? name : $0 }
            if current == old { current = name; state.current = name }
            persist()
            refresh()
        }
    }

    func trash(_ tab: String) {
        guard tabs.count > 1 else { notice = "the last Tab stays"; return }
        saveAll()
        do {
            try FileManager.default.trashItem(at: url(of: tab), resultingItemURL: nil)
        } catch {
            notice = "could not move \(tab) to the Trash"; return
        }
        docs[tab] = nil
        refresh()
    }

    /// drag and drop in the tab bar: `tab` goes in front of `target`
    func move(_ tab: String, before target: String) {
        var order = state.order
        guard tab != target, let from = order.firstIndex(of: tab) else { return }
        order.remove(at: from)
        order.insert(tab, at: order.firstIndex(of: target) ?? order.count)
        state.order = order
        persist()
        refresh()
    }

    // MARK: Cmd+P

    /// Tab names, and every non-empty line of every Tab once there is a query.
    func search(_ query: String) -> [Hit] {
        saveAll()
        let all = NotesLibrary.order(files: NotesLibrary.names(in: folder), saved: state.order)
        // no query: the Tabs in their own order, closed ones included
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return all.enumerated().map { Hit(id: $0.offset, tab: $0.element, line: nil, label: $0.element) }
        }
        var items: [(tab: String, line: Int?, label: String)] = all.map { ($0, nil, $0) }
        for tab in all {
            let text = docs[tab]?.text ?? read(tab)
            for (n, line) in text.components(separatedBy: "\n").enumerated() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                items.append((tab, n, "\(tab)  \(line.trimmingCharacters(in: .whitespaces))"))
            }
        }
        let ranked = Matcher.rank(items, query: query, label: { $0.label }, rank: { $0.line == nil ? 1 : 0 })
        return ranked.prefix(50).enumerated().map { Hit(id: $0.offset, tab: $0.element.tab, line: $0.element.line, label: $0.element.label) }
    }

    func persist() { state.save(to: stateURL) }
}
