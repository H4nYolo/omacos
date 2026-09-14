import Foundation
import Testing
@testable import OmacosCore

private struct FakeShell: ShellRunner {
    func run(_ command: String) -> (output: String, status: Int32) {
        switch command {
        case "state-on": return ("on", 0)
        case "false": return ("", 1)
        default: return ("", 0)
        }
    }
}

private let json = """
{ "_": "comment", "entries": [
  { "icon": "A", "label": "Apps", "view": "launcher" },
  { "icon": "T", "label": "Toggle", "id": "toggle", "menu": [
    { "icon": "B", "label": "Bar", "run": "omacos-toggle bar", "state": "state-on" },
    { "icon": "R", "label": "Stop", "run": "omacos-capture stop", "when": "false" },
    { "icon": "N", "label": "Notes", "popup": "notes" },
    { "icon": "K", "label": "tmux keys", "view": "keys", "args": "tmux" }
  ]}
]}
"""

@Suite struct MenuTests {
    @Test func decodesKinds() throws {
        let menu = try JSONDecoder().decode(MenuFile.self, from: Data(json.utf8))
        #expect(menu.entries.count == 2)
        #expect(menu.entries[0].kind == .view(name: "launcher", args: ""))
        guard case .menu(let id, let children) = menu.entries[1].kind else { Issue.record("Toggle should be a submenu"); return }
        #expect(id == "toggle")
        #expect(children[0].kind == .run(command: "omacos-toggle bar"))
        #expect(children[2].kind == .popup(name: "notes"))
        #expect(children[3].kind == .view(name: "keys", args: "tmux"))
    }

    @Test func levelLookupByRoute() throws {
        let menu = try JSONDecoder().decode(MenuFile.self, from: Data(json.utf8))
        #expect(menu.level(at: [])?.count == 2)
        #expect(menu.level(at: ["toggle"])?.count == 4)
        #expect(menu.level(at: ["nope"]) == nil)
    }

    @Test func stateAndWhen() throws {
        let menu = try JSONDecoder().decode(MenuFile.self, from: Data(json.utf8))
        let rows = menu.level(at: ["toggle"])!.resolved(with: FakeShell())
        #expect(rows.map(\.label) == ["Bar  [on]", "Notes", "tmux keys"])
    }

    @Test func descendantsCarryBreadcrumbsAndPaths() throws {
        let menu = try JSONDecoder().decode(MenuFile.self, from: Data(json.utf8))
        let all = menu.descendants(below: [])!
        #expect(all.map(\.label) == ["Apps", "Toggle", "Toggle › Bar", "Toggle › Stop", "Toggle › Notes", "Toggle › tmux keys"])
        #expect(all[2].path == ["toggle"] && all[2].depth == 1)
        #expect(all[1].path == [] && all[1].depth == 0)
        #expect(menu.descendants(below: ["toggle"])?.map(\.label) == ["Bar", "Stop", "Notes", "tmux keys"])
        #expect(menu.descendants(below: ["nope"]) == nil)
        let resolved = all.resolved(with: FakeShell())
        #expect(resolved.map(\.label) == ["Apps", "Toggle", "Toggle › Bar  [on]", "Toggle › Notes", "Toggle › tmux keys"])
        #expect(resolved[2].path == ["toggle"])
    }

    @Test func entryWithoutKindFails() {
        let bad = Data(#"{ "entries": [ { "label": "broken" } ] }"#.utf8)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(MenuFile.self, from: bad) }
    }

    @Test func theRealMenuFileParses() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("omacos/.config/omacos/menu.json")
        let menu = try MenuFile.load(from: url)
        #expect(menu.entries.count == 13)
        #expect(menu.level(at: ["capture"])?.count == 9)
    }
}
