import Foundation

/// ~/.config/omacos/menu.json — the Menu tree shared with the fzf `omacos-menu` (ADR 0003).
public struct MenuFile: Decodable {
    public let entries: [MenuEntry]
}

public struct MenuEntry: Decodable {
    public enum Kind: Equatable {
        case menu(id: String, children: [MenuEntry])
        case view(name: String, args: String)
        case popup(name: String)
        case run(command: String)

        public static func == (a: Kind, b: Kind) -> Bool {
            switch (a, b) {
            case let (.menu(x, _), .menu(y, _)): return x == y
            case let (.view(n1, a1), .view(n2, a2)): return n1 == n2 && a1 == a2
            case let (.popup(x), .popup(y)): return x == y
            case let (.run(x), .run(y)): return x == y
            default: return false
            }
        }
    }

    public let icon: String
    public let label: String
    public let kind: Kind
    /// shell command whose output is appended as " [output]"
    public let state: String?
    /// shell command; the entry is shown only when it exits 0
    public let when: String?

    enum CodingKeys: String, CodingKey { case icon, label, id, menu, view, args, popup, run, state, when }

    public init(icon: String, label: String, kind: Kind, state: String? = nil, when: String? = nil) {
        self.icon = icon; self.label = label; self.kind = kind; self.state = state; self.when = when
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? ""
        label = try c.decode(String.self, forKey: .label)
        state = try c.decodeIfPresent(String.self, forKey: .state)
        when = try c.decodeIfPresent(String.self, forKey: .when)
        if let children = try c.decodeIfPresent([MenuEntry].self, forKey: .menu) {
            let id = try c.decodeIfPresent(String.self, forKey: .id) ?? label.lowercased()
            kind = .menu(id: id, children: children)
        } else if let view = try c.decodeIfPresent(String.self, forKey: .view) {
            kind = .view(name: view, args: try c.decodeIfPresent(String.self, forKey: .args) ?? "")
        } else if let popup = try c.decodeIfPresent(String.self, forKey: .popup) {
            kind = .popup(name: popup)
        } else if let run = try c.decodeIfPresent(String.self, forKey: .run) {
            kind = .run(command: run)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .label, in: c, debugDescription: "entry '\(label)' has none of menu/view/popup/run")
        }
    }
}

public extension MenuFile {
    static func load(from url: URL) throws -> MenuFile {
        try JSONDecoder().decode(MenuFile.self, from: Data(contentsOf: url))
    }

    /// The entries of the level reached by following submenu ids from the root; nil if the path is unknown.
    func level(at path: [String]) -> [MenuEntry]? {
        var current = entries
        for id in path {
            guard let next = current.first(where: { if case .menu(let i, _) = $0.kind { return i == id } else { return false } }),
                  case .menu(_, let children) = next.kind else { return nil }
            current = children
        }
        return current
    }

    /// Every entry at or below the level at `path`, in file order, depth first. Entries below the
    /// level carry a breadcrumb label ("Style › Background") so a search from the top finds them.
    /// nil if the path is unknown.
    func descendants(below path: [String]) -> [ResolvedEntry]? {
        guard let entries = level(at: path) else { return nil }
        var out: [ResolvedEntry] = []
        func walk(_ entries: [MenuEntry], path: [String], crumbs: [String]) {
            for e in entries {
                let label = (crumbs + [e.label]).joined(separator: MenuFile.crumbSeparator)
                out.append(ResolvedEntry(entry: e, label: label, path: path, depth: crumbs.count))
                if case .menu(let id, let children) = e.kind {
                    walk(children, path: path + [id], crumbs: crumbs + [e.label])
                }
            }
        }
        walk(entries, path: path, crumbs: [])
        return out
    }

    static let crumbSeparator = " › "
}

/// A shell runner, injectable so tests need no /bin/sh.
public protocol ShellRunner {
    /// stdout (trimmed) and exit status of `/bin/sh -c command`
    func run(_ command: String) -> (output: String, status: Int32)
}

/// A Menu entry as shown in a level: its display label (breadcrumb and state included), the
/// level it lives in (`path`, submenu ids from the root) and how far below the opened level it sits.
public struct ResolvedEntry: Equatable {
    public let entry: MenuEntry
    public let label: String
    public let path: [String]
    public let depth: Int
    public init(entry: MenuEntry, label: String, path: [String] = [], depth: Int = 0) {
        self.entry = entry; self.label = label; self.path = path; self.depth = depth
    }
    public static func == (a: ResolvedEntry, b: ResolvedEntry) -> Bool {
        a.label == b.label && a.entry.kind == b.entry.kind && a.path == b.path
    }
}

public extension Array where Element == MenuEntry {
    /// Evaluate `when` (drop) and `state` (append " [output]") with the given shell.
    func resolved(with shell: ShellRunner) -> [ResolvedEntry] {
        map { ResolvedEntry(entry: $0, label: $0.label) }.resolved(with: shell)
    }
}

public extension Array where Element == ResolvedEntry {
    /// Evaluate `when` (drop) and `state` (append " [output]") with the given shell, keeping labels and paths.
    func resolved(with shell: ShellRunner) -> [ResolvedEntry] {
        compactMap { r in
            if let w = r.entry.when, shell.run(w).status != 0 { return nil }
            var label = r.label
            if let s = r.entry.state { label += "  [\(shell.run(s).output)]" }
            return ResolvedEntry(entry: r.entry, label: label, path: r.path, depth: r.depth)
        }
    }
}
