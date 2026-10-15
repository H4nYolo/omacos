import AppKit
import OmacosCore
import VimEngine

/// The editor: an NSTextView whose keys go through the vendored vim engine first. Normal and
/// visual mode swallow what the engine does not know; insert mode types like any text view.
/// Clicking a checkbox toggles it, Cmd+click opens a link.
final class NotesTextView: NSTextView {
    let vim = VimEngine()

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) { super.keyDown(with: event); return }
        if vim.handleKey(chars: event.charactersIgnoringModifiers, keyCode: event.keyCode,
                         modifiers: KeyModifiers(flags), editor: self) {
            return
        }
        let arrows: ClosedRange<UInt16> = 123...126
        if vim.submode == .insert {
            if flags.isDisjoint(with: [.control, .option]) && typingHelper(event.keyCode) { return }
            super.keyDown(with: event)
        } else if arrows.contains(event.keyCode) {
            super.keyDown(with: event)
        }
    }

    // MARK: typing helpers (insert mode)

    /// `/t` `/h` `/d` + space at the start of a line, and Enter continuing lists. true = handled.
    private func typingHelper(_ keyCode: UInt16) -> Bool {
        let ns = string as NSString
        let cursor = selectedRange()
        guard cursor.length == 0 else { return false }
        let line = ns.lineRange(for: NSRange(location: cursor.location, length: 0))
        var contentsEnd = 0
        ns.getLineStart(nil, end: nil, contentsEnd: &contentsEnd, for: line)
        let lineStart = line.location
        switch keyCode {
        case 49:                                                            // space
            let typed = ns.substring(with: NSRange(location: lineStart, length: cursor.location - lineStart))
            guard let expanded = NotesEditing.expandSlash(typed) else { return false }
            replace(in: NSRange(location: lineStart, length: cursor.location - lineStart), with: expanded)
            setSelectedRange(NSRange(location: lineStart + (expanded as NSString).length, length: 0))
            return true
        case 36, 76:                                                        // enter, only at the end of a line
            guard cursor.location == contentsEnd else { return false }
            let text = ns.substring(with: NSRange(location: lineStart, length: contentsEnd - lineStart))
            switch NotesEditing.continuation(text) {
            case .none:
                return false
            case .clear:
                replace(in: NSRange(location: lineStart, length: contentsEnd - lineStart), with: "")
                setSelectedRange(NSRange(location: lineStart, length: 0))
            case .insert(let prefix):
                replace(in: cursor, with: "\n" + prefix)
                setSelectedRange(NSRange(location: cursor.location + 1 + (prefix as NSString).length, length: 0))
            }
            return true
        default:
            return false
        }
    }

    /// Cmd+Shift+X: the current line's checkbox flips, or the line becomes an open task.
    func toggleTask() {
        let ns = string as NSString
        let cursor = selectedRange().location
        var start = 0, contentsEnd = 0
        ns.getLineStart(&start, end: nil, contentsEnd: &contentsEnd, for: NSRange(location: min(cursor, ns.length), length: 0))
        let old = ns.substring(with: NSRange(location: start, length: contentsEnd - start))
        let new = NotesEditing.toggleTask(old)
        replace(in: NSRange(location: start, length: contentsEnd - start), with: new)
        // the cursor keeps its place in the text after the marker
        let moved = max(start, min(cursor + (new as NSString).length - (old as NSString).length, start + (new as NSString).length))
        setSelectedRange(NSRange(location: moved, length: 0))
    }

    // MARK: block cursor outside insert mode

    private var blockCursor: Bool { vim.submode != .insert }

    private var cellWidth: CGFloat {
        ("M" as NSString).size(withAttributes: [.font: font ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)]).width
    }

    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard blockCursor else { super.drawInsertionPoint(in: rect, color: color, turnedOn: flag); return }
        guard flag else { setNeedsDisplay(blockRect(rect), avoidAdditionalLayout: true); return }
        color.withAlphaComponent(0.45).setFill()
        blockRect(rect).fill()
    }

    private func blockRect(_ rect: NSRect) -> NSRect {
        NSRect(x: rect.minX, y: rect.minY, width: cellWidth, height: rect.height)
    }

    // the text view only repaints the thin caret; widen that so the block leaves no trail
    override func setNeedsDisplay(_ rect: NSRect, avoidAdditionalLayout flag: Bool) {
        var r = rect
        if blockCursor && rect.width <= 2 { r.size.width = cellWidth + 1 }
        super.setNeedsDisplay(r, avoidAdditionalLayout: flag)
    }

    /// called when the vim mode changes so the cursor shape follows
    func refreshCursor() {
        updateInsertionPointStateAndRestartTimer(true)
        setNeedsDisplay(visibleRect)
    }

    // MARK: clicks

    override func mouseDown(with event: NSEvent) {
        if let index = characterIndex(at: convert(event.locationInWindow, from: nil)), let storage = textStorage {
            if storage.attribute(.mdCheckbox, at: index, effectiveRange: nil) != nil {
                let checked = (storage.string as NSString).substring(with: NSRange(location: index, length: 1)) != " "
                replace(in: NSRange(location: index, length: 1), with: checked ? " " : "x")
                return
            }
            if event.modifierFlags.contains(.command),
               let url = (storage.attribute(.mdLink, at: index, effectiveRange: nil) as? String).flatMap(URL.init(string:)) {
                NSWorkspace.shared.open(url)
                return
            }
        }
        super.mouseDown(with: event)
    }

    /// the character drawn under a point, nil between lines or past their ends
    private func characterIndex(at point: NSPoint) -> Int? {
        guard let layoutManager, let textContainer else { return nil }
        let p = NSPoint(x: point.x - textContainerOrigin.x, y: point.y - textContainerOrigin.y)
        var fraction: CGFloat = 0
        let glyph = layoutManager.glyphIndex(for: p, in: textContainer, fractionOfDistanceThroughGlyph: &fraction)
        guard glyph < layoutManager.numberOfGlyphs,
              layoutManager.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: textContainer).contains(p)
        else { return nil }
        return layoutManager.characterIndexForGlyph(at: glyph)
    }
}
