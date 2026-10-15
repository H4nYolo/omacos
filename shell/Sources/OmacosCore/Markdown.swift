import Foundation

/// The markdown subset Notes renders (ADR 0004): headings, **bold**, *italic*, ~~strike~~,
/// `code`, fenced code blocks, lists, checkboxes, quotes, links, rules. Everything is an
/// NSRange in UTF-16 units so it maps straight onto an NSTextStorage.
///
/// `markers` are the characters that disappear off the cursor line (`# `, `**`, `](url)` …);
/// `glyphs` swap one character for a symbol (the list dash becomes a bullet, `[ ]` a box).
public enum Markdown {
    public enum Style: Equatable {
        case heading(Int)
        case bold, italic, strike, code, codeBlock, quote, rule
        case link(String)
        case done            // the text of a checked checkbox
        case marker          // syntax characters, dimmed where they are visible
    }

    public enum Glyph: Equatable { case bullet, box, checkedBox }

    public struct Layout: Equatable {
        public var styles: [(range: NSRange, style: Style)] = []
        public var markers: [NSRange] = []
        public var glyphs: [(location: Int, glyph: Glyph)] = []
        /// the character between `[` and `]`, for clicking a checkbox
        public var checkboxes: [(location: Int, checked: Bool)] = []

        public static func == (a: Layout, b: Layout) -> Bool {
            a.styles.elementsEqual(b.styles) { $0.range == $1.range && $0.style == $1.style }
                && a.markers == b.markers
                && a.glyphs.elementsEqual(b.glyphs) { $0.location == $1.location && $0.glyph == $1.glyph }
                && a.checkboxes.elementsEqual(b.checkboxes) { $0.location == $1.location && $0.checked == $1.checked }
        }
    }

    public static func layout(_ text: String) -> Layout {
        var out = Layout()
        let ns = text as NSString
        var inFence = false
        var location = 0
        while location < ns.length || (location == 0 && ns.length == 0) {
            var lineEnd = 0, contentsEnd = 0
            ns.getLineStart(nil, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))
            let line = NSRange(location: location, length: contentsEnd - location)
            let body = ns.substring(with: line)
            if body.hasPrefix("```") {
                // the fence lines themselves are syntax; the lines between are code
                out.styles.append((line, .marker))
                out.markers.append(line)
                inFence.toggle()
            } else if inFence {
                out.styles.append((line, .codeBlock))
            } else {
                block(body, line, &out)
            }
            if lineEnd == location { break }
            location = lineEnd
        }
        return out
    }

    // MARK: blocks

    private static let heading = try! NSRegularExpression(pattern: "^(#{1,6}) +")
    private static let rule = try! NSRegularExpression(pattern: "^ {0,3}([-*_])( *\\1){2,} *$")
    private static let quote = try! NSRegularExpression(pattern: "^ {0,3}> ?")
    private static let task = try! NSRegularExpression(pattern: "^( *)([-*+]) \\[([ xX])\\] ")
    private static let bullet = try! NSRegularExpression(pattern: "^( *)([-*+]) ")

    private static func block(_ body: String, _ line: NSRange, _ out: inout Layout) {
        let local = NSRange(location: 0, length: (body as NSString).length)
        func shift(_ r: NSRange) -> NSRange { NSRange(location: line.location + r.location, length: r.length) }

        if let m = heading.firstMatch(in: body, range: local) {
            let level = m.range(at: 1).length
            out.styles.append((line, .heading(level)))
            out.styles.append((shift(m.range), .marker))
            out.markers.append(shift(m.range))
            inline(body, line, from: m.range.length, &out)
            return
        }
        if rule.firstMatch(in: body, range: local) != nil {
            out.styles.append((line, .rule))
            return
        }
        if let m = quote.firstMatch(in: body, range: local) {
            out.styles.append((line, .quote))
            out.styles.append((shift(m.range), .marker))
            out.markers.append(shift(m.range))
            inline(body, line, from: m.range.length, &out)
            return
        }
        if let m = task.firstMatch(in: body, range: local) {
            // "- [x] " → the dash and the brackets vanish, the middle character becomes the box
            let dash = m.range(at: 2), mark = m.range(at: 3)
            let checked = (body as NSString).substring(with: mark) != " "
            let open = NSRange(location: dash.location, length: mark.location - dash.location)   // "- ["
            let close = NSRange(location: mark.location + 1, length: 1)                          // "]"
            for r in [open, close] { out.styles.append((shift(r), .marker)); out.markers.append(shift(r)) }
            out.glyphs.append((line.location + mark.location, checked ? .checkedBox : .box))
            out.checkboxes.append((line.location + mark.location, checked))
            if checked {
                let rest = NSRange(location: line.location + m.range.length, length: line.length - m.range.length)
                if rest.length > 0 { out.styles.append((rest, .done)) }
            }
            inline(body, line, from: m.range.length, &out)
            return
        }
        if let m = bullet.firstMatch(in: body, range: local) {
            out.glyphs.append((line.location + m.range(at: 2).location, .bullet))
            inline(body, line, from: m.range.length, &out)
            return
        }
        inline(body, line, from: 0, &out)
    }

    // MARK: inline

    private static let codeSpan = try! NSRegularExpression(pattern: "(`)([^`]+)(`)")
    private static let spans: [(NSRegularExpression, Style)] = [
        (try! NSRegularExpression(pattern: "(\\*\\*|__)(?=\\S)(.+?)(?<=\\S)(\\1)"), .bold),
        (try! NSRegularExpression(pattern: "(~~)(?=\\S)(.+?)(?<=\\S)(~~)"), .strike),
        (try! NSRegularExpression(pattern: "(?<![*\\w])(\\*|_)(?=[^\\s*_])(.+?)(?<=[^\\s*_])(\\1)(?![*\\w])"), .italic),
    ]
    private static let link = try! NSRegularExpression(pattern: "(\\[)([^\\]]+)(\\]\\(([^)\\s]+)\\))")

    private static func inline(_ body: String, _ line: NSRange, from start: Int, _ out: inout Layout) {
        let ns = body as NSString
        let search = NSRange(location: start, length: ns.length - start)
        guard search.length > 0 else { return }
        func shift(_ r: NSRange) -> NSRange { NSRange(location: line.location + r.location, length: r.length) }
        func hide(_ r: NSRange) { out.styles.append((shift(r), .marker)); out.markers.append(shift(r)) }

        // code first: nothing inside backticks is markdown
        var taken: [NSRange] = []
        for m in codeSpan.matches(in: body, range: search) {
            out.styles.append((shift(m.range(at: 2)), .code))
            hide(m.range(at: 1)); hide(m.range(at: 3))
            taken.append(m.range)
        }
        func free(_ r: NSRange) -> Bool { !taken.contains { NSIntersectionRange($0, r).length > 0 } }

        for m in link.matches(in: body, range: search) where free(m.range) {
            out.styles.append((shift(m.range(at: 2)), .link(ns.substring(with: m.range(at: 4)))))
            hide(m.range(at: 1)); hide(m.range(at: 3))
            taken.append(m.range(at: 3))   // the url itself is not markdown; the label may be
        }
        for (regex, style) in spans {
            for m in regex.matches(in: body, range: search) where free(m.range(at: 1)) && free(m.range(at: 3)) {
                out.styles.append((shift(m.range(at: 2)), style))
                hide(m.range(at: 1)); hide(m.range(at: 3))
                taken.append(m.range(at: 1)); taken.append(m.range(at: 3))
            }
        }
    }
}
