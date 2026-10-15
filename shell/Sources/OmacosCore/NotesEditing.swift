import Foundation

/// The typing helpers of Notes, as pure functions on one line of text (ADR 0004):
/// `/t` `/h` `/d` + space at the start of a line, Enter continuing lists, Cmd+Shift+X for tasks.
public enum NotesEditing {
    /// What typing a space after `typed` (the line up to the cursor) turns that text into, or nil.
    /// Only at the start of a line, so "and/then" in a sentence stays as it is.
    public static func expandSlash(_ typed: String, timestamp: () -> String = { NotesLibrary.timestamp() }) -> String? {
        let indent = String(typed.prefix { $0 == " " || $0 == "\t" })
        switch typed.dropFirst(indent.count) {
        case "/t": return indent + "- [ ] "
        case "/h": return indent + "## "
        case "/d": return indent + timestamp()
        default: return nil
        }
    }

    public enum Continuation: Equatable {
        case none
        /// insert a newline plus this prefix
        case insert(String)
        /// the line is only a list marker: Enter ends the list and empties the line
        case clear
    }

    private static let task = try! NSRegularExpression(pattern: "^(\\s*)[-*+] \\[[ xX]\\] (.*)$")
    private static let bullet = try! NSRegularExpression(pattern: "^(\\s*)([-*+]) (.*)$")
    private static let numbered = try! NSRegularExpression(pattern: "^(\\s*)(\\d+)([.)]) (.*)$")

    /// Enter at the end of `line`: tasks continue as open tasks, bullets as bullets, numbers count up.
    public static func continuation(_ line: String) -> Continuation {
        let ns = line as NSString
        let all = NSRange(location: 0, length: ns.length)
        func group(_ m: NSTextCheckingResult, _ i: Int) -> String { ns.substring(with: m.range(at: i)) }
        if let m = task.firstMatch(in: line, range: all) {
            return group(m, 2).isEmpty ? .clear : .insert(group(m, 1) + "- [ ] ")
        }
        if let m = numbered.firstMatch(in: line, range: all) {
            return group(m, 4).isEmpty ? .clear : .insert(group(m, 1) + "\((Int(group(m, 2)) ?? 0) + 1)" + group(m, 3) + " ")
        }
        if let m = bullet.firstMatch(in: line, range: all) {
            return group(m, 3).isEmpty ? .clear : .insert(group(m, 1) + group(m, 2) + " ")
        }
        return .none
    }

    /// Cmd+Shift+X: `- [ ]` ↔ `- [x]`; a bullet or plain line becomes an open task.
    public static func toggleTask(_ line: String) -> String {
        let ns = line as NSString
        let all = NSRange(location: 0, length: ns.length)
        if task.firstMatch(in: line, range: all) != nil, let r = line.range(of: "\\[[ xX]\\]", options: .regularExpression) {
            return line.replacingCharacters(in: r, with: line[r] == "[ ]" ? "[x]" : "[ ]")
        }
        if let m = bullet.firstMatch(in: line, range: all) {
            return ns.substring(with: m.range(at: 1)) + ns.substring(with: m.range(at: 2)) + " [ ] " + ns.substring(with: m.range(at: 3))
        }
        let indent = String(line.prefix { $0 == " " || $0 == "\t" })
        return indent + "- [ ] " + line.dropFirst(indent.count)
    }
}
