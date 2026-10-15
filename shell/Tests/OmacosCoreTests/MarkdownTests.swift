import Foundation
import Testing
@testable import OmacosCore

@Suite struct MarkdownTests {
    func text(_ s: String, _ r: NSRange) -> String { (s as NSString).substring(with: r) }
    func styled(_ s: String, _ style: Markdown.Style) -> [String] {
        Markdown.layout(s).styles.filter { $0.style == style }.map { text(s, $0.range) }
    }
    func hidden(_ s: String) -> [String] { Markdown.layout(s).markers.map { text(s, $0) } }

    @Test func headingHidesHashesAndStylesTheLine() {
        let s = "## Incident\nplain"
        #expect(styled(s, .heading(2)) == ["## Incident"])
        #expect(hidden(s) == ["## "])
        #expect(styled("#nospace", .heading(1)).isEmpty)
    }

    @Test func inlineEmphasis() {
        let s = "a **bold** and *it* and ~~gone~~ and `co*de*`"
        #expect(styled(s, .bold) == ["bold"])
        #expect(styled(s, .italic) == ["it"])
        #expect(styled(s, .strike) == ["gone"])
        #expect(styled(s, .code) == ["co*de*"])          // nothing inside backticks is markdown
        #expect(hidden(s) == ["`", "`", "**", "**", "~~", "~~", "*", "*"])
    }

    @Test func snakeCaseIsNotItalic() {
        #expect(styled("INC_1234_x and a*b*c", .italic).isEmpty)
    }

    @Test func linkShowsOnlyTheLabel() {
        let s = "see [the ticket](https://x.example/INC-1) now"
        let layout = Markdown.layout(s)
        #expect(layout.styles.contains { $0.style == .link("https://x.example/INC-1") && text(s, $0.range) == "the ticket" })
        #expect(hidden(s) == ["[", "](https://x.example/INC-1)"])
    }

    @Test func checkboxesBecomeBoxesAndCheckedTextIsDone() {
        let s = "- [ ] call back\n- [x] wrote it down"
        let layout = Markdown.layout(s)
        #expect(hidden(s) == ["- [", "]", "- [", "]"])
        #expect(layout.glyphs.map(\.glyph) == [.box, .checkedBox])
        #expect(layout.checkboxes.map { text(s, NSRange(location: $0.location, length: 1)) } == [" ", "x"])
        #expect(styled(s, .done) == ["wrote it down"])
    }

    @Test func bulletsAndQuotes() {
        let s = "- one\n  * two\n> quoted **loud**"
        let layout = Markdown.layout(s)
        #expect(layout.glyphs.map { text(s, NSRange(location: $0.location, length: 1)) } == ["-", "*"])
        #expect(styled(s, .quote) == ["> quoted **loud**"])
        #expect(styled(s, .bold) == ["loud"])
        #expect(hidden(s) == ["> ", "**", "**"])
    }

    @Test func fencedCodeIsLeftAlone() {
        let s = "```sh\n# not a heading\n```\n# heading"
        #expect(styled(s, .codeBlock) == ["# not a heading"])
        #expect(styled(s, .heading(1)) == ["# heading"])
        #expect(hidden(s) == ["```sh", "```", "# "])
    }

    @Test func rulesAndEdgeCases() {
        #expect(styled("---", .rule) == ["---"])
        #expect(styled("* * *", .rule) == ["* * *"])
        #expect(Markdown.layout("") == Markdown.Layout())
        #expect(Markdown.layout("\n\n") == Markdown.Layout())
    }

    @Test func rangesAreUTF16() {
        let s = "🙂 **x**"
        #expect(styled(s, .bold) == ["x"])
    }
}

@Suite struct NotesLibraryTests {
    @Test func savedOrderFirstThenNewFilesByName() {
        #expect(NotesLibrary.order(files: ["b", "quick", "a10", "a2"], saved: ["quick", "gone", "b"]) == ["quick", "b", "a2", "a10"])
        #expect(NotesLibrary.order(files: ["x"], saved: ["x", "x"]) == ["x"])
    }

    @Test func namesAreMarkdownFilesOnly() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("sub.md"), withIntermediateDirectories: true)
        for f in ["quick.md", "MAN.md", ".hidden.md", "notes.txt"] {
            try Data().write(to: dir.appendingPathComponent(f))
        }
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(Set(NotesLibrary.names(in: dir)) == ["quick", "MAN"])
    }

    @Test func sanitize() {
        #expect(NotesLibrary.sanitize("  incidents.md ") == "incidents")
        #expect(NotesLibrary.sanitize("a/b:c") == "a-b-c")
        #expect(NotesLibrary.sanitize("..secret") == "secret")
        #expect(NotesLibrary.sanitize("   ") == nil)
    }

    @Test func timestampLooksLikeTheOldPad() {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = 15; c.hour = 9; c.minute = 5
        let date = Calendar(identifier: .gregorian).date(from: c)!
        #expect(NotesLibrary.timestamp(date) == "## Thu 15 Oct 2026 09:05")
    }

    @Test func stateLoadsOldFilesAndStepsOpacity() throws {
        let state = try JSONDecoder().decode(NotesState.self, from: Data(#"{"width": 600}"#.utf8))
        #expect(state.width == 600 && state.height == NotesState().height)
        #expect(NotesState.step(0.85, by: 0.1) == 0.95)
        #expect(NotesState.step(0.95, by: 0.1) == 1)
        #expect(NotesState.step(0.1, by: -0.1) == 0.05)
    }
}

@Suite struct ThemeConfigTests {
    @Test func parsesHexLines() {
        let c = ThemeConfig.colors("# comment\nbg=#1a1b26\nfg = c0caf5\nbad=#12\n")
        #expect(c == ["bg": 0x1a1b26, "fg": 0xc0caf5])
    }
}
