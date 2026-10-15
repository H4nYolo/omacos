import AppKit
import OmacosCore

extension NSAttributedString.Key {
    /// markdown syntax: dimmed on the cursor line, gone everywhere else
    static let mdMarker = NSAttributedString.Key("omacos.md.marker")
    /// the symbol this one character is drawn as (bullet, checkbox) off the cursor line
    static let mdGlyph = NSAttributedString.Key("omacos.md.glyph")
    /// Bool: the character inside `[ ]` / `[x]`, clicking it toggles the box
    static let mdCheckbox = NSAttributedString.Key("omacos.md.checkbox")
    /// String: the url behind a link label, Cmd+click opens it
    static let mdLink = NSAttributedString.Key("omacos.md.link")
}

/// Typora-style rendering (ADR 0004). The text storage always holds the plain markdown; styles
/// are attributes recomputed after every edit, and the layout manager delegate hides the markers
/// at glyph generation — except on the lines in `rawRange` (the cursor's), which stay raw.
@MainActor
final class MarkdownRenderer: NSObject, @preconcurrency NSTextStorageDelegate, @preconcurrency NSLayoutManagerDelegate {
    var fontSize: CGFloat = 14
    private(set) var rawRange = NSRange(location: NSNotFound, length: 0)
    weak var layoutManager: NSLayoutManager?

    var baseAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        return [.font: NotesTheme.font(fontSize), .foregroundColor: NotesTheme.fg, .paragraphStyle: paragraph]
    }

    // MARK: styling

    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        guard editedMask.contains(.editedCharacters) else { return }
        restyle(textStorage)
    }

    /// Notes are short, so the whole text is restyled — fences and lists need their context anyway.
    func restyle(_ storage: NSTextStorage) {
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }
        let layout = Markdown.layout(storage.string)
        storage.setAttributes(baseAttributes, range: full)
        for (range, style) in layout.styles { apply(style, range, storage) }
        for range in layout.markers { storage.addAttribute(.mdMarker, value: true, range: range) }
        for (location, glyph) in layout.glyphs {
            storage.addAttribute(.mdGlyph, value: symbol(glyph), range: NSRange(location: location, length: 1))
        }
        for (location, checked) in layout.checkboxes {
            storage.addAttribute(.mdCheckbox, value: checked, range: NSRange(location: location, length: 1))
        }
    }

    private func apply(_ style: Markdown.Style, _ range: NSRange, _ s: NSTextStorage) {
        switch style {
        case .heading(let level):
            let scale: CGFloat = [1.5, 1.3, 1.15][min(level, 3) - 1]
            s.addAttributes([.font: NotesTheme.font(fontSize * scale, bold: true), .foregroundColor: NotesTheme.accent], range: range)
        case .bold:
            convertFonts(range, s) { NSFontManager.shared.convert($0, toHaveTrait: .boldFontMask) }
        case .italic:
            convertFonts(range, s) { NSFontManager.shared.convert($0, toHaveTrait: .italicFontMask) }
        case .strike:
            s.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        case .code, .codeBlock:
            s.addAttribute(.backgroundColor, value: NotesTheme.bgSelected, range: range)
        case .quote:
            s.addAttribute(.foregroundColor, value: NotesTheme.dim, range: range)
            convertFonts(range, s) { NSFontManager.shared.convert($0, toHaveTrait: .italicFontMask) }
        case .rule:
            s.addAttribute(.foregroundColor, value: NotesTheme.border, range: range)
        case .link(let url):
            s.addAttributes([.foregroundColor: NotesTheme.accent, .underlineStyle: NSUnderlineStyle.single.rawValue, .mdLink: url], range: range)
        case .done:
            s.addAttributes([.foregroundColor: NotesTheme.dim, .strikethroughStyle: NSUnderlineStyle.single.rawValue], range: range)
        case .marker:
            s.addAttribute(.foregroundColor, value: NotesTheme.dim, range: range)
        }
    }

    /// bold inside a heading stays heading-sized: change the trait of whatever font is there
    private func convertFonts(_ range: NSRange, _ s: NSTextStorage, _ convert: (NSFont) -> NSFont) {
        s.enumerateAttribute(.font, in: range) { value, sub, _ in
            if let font = value as? NSFont { s.addAttribute(.font, value: convert(font), range: sub) }
        }
    }

    private func symbol(_ glyph: Markdown.Glyph) -> String {
        switch glyph {
        case .bullet: return "•"
        case .box: return "\u{F096}"         // nf-fa-square_o
        case .checkedBox: return "\u{F046}"  // nf-fa-check_square_o
        }
    }

    // MARK: the cursor line

    /// The paragraphs that show their markdown; relayouts the lines that change state.
    func setRawRange(_ range: NSRange, length: Int) {
        guard range != rawRange else { return }
        let old = rawRange
        rawRange = range
        guard let layoutManager else { return }
        for r in [old, range] where r.location != NSNotFound {
            let clamped = NSIntersectionRange(r, NSRange(location: 0, length: length))
            guard clamped.length > 0 || r.location < length else { continue }
            layoutManager.invalidateGlyphs(forCharacterRange: clamped, changeInLength: 0, actualCharacterRange: nil)
            layoutManager.invalidateLayout(forCharacterRange: clamped, actualCharacterRange: nil)
        }
    }

    func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
                       properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
                       characterIndexes charIndexes: UnsafePointer<Int>, font aFont: NSFont,
                       forGlyphRange glyphRange: NSRange) -> Int {
        guard let storage = layoutManager.textStorage, glyphRange.length > 0 else { return 0 }
        var newGlyphs = Array(UnsafeBufferPointer(start: glyphs, count: glyphRange.length))
        var newProps = Array(UnsafeBufferPointer(start: props, count: glyphRange.length))
        var changed = false
        for i in 0..<glyphRange.length {
            let index = charIndexes[i]
            guard index < storage.length, !NSLocationInRange(index, rawRange) else { continue }
            if storage.attribute(.mdMarker, at: index, effectiveRange: nil) != nil {
                newProps[i] = .null
                changed = true
            } else if let symbol = storage.attribute(.mdGlyph, at: index, effectiveRange: nil) as? String,
                      let glyph = glyph(for: symbol, in: aFont) {
                newGlyphs[i] = glyph
                changed = true
            }
        }
        guard changed else { return 0 }
        layoutManager.setGlyphs(newGlyphs, properties: newProps, characterIndexes: charIndexes, font: aFont, forGlyphRange: glyphRange)
        return glyphRange.length
    }

    private func glyph(for symbol: String, in font: NSFont) -> CGGlyph? {
        let units = Array(symbol.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: units.count)
        guard CTFontGetGlyphsForCharacters(font as CTFont, units, &glyphs, units.count), glyphs[0] != 0 else { return nil }
        return glyphs[0]
    }
}
