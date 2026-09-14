import Foundation

/// ~/.config/omacos/emoji.tsv — "emoji<TAB>name<TAB>keywords" (from gemoji).
public struct EmojiEntry: Equatable {
    public let emoji: String
    public let name: String
    public let keywords: String
    /// what the search runs over
    public var searchText: String { name + " " + keywords }
    public init(emoji: String, name: String, keywords: String) { self.emoji = emoji; self.name = name; self.keywords = keywords }
}

public enum EmojiTable {
    public static func parse(_ text: String) -> [EmojiEntry] {
        text.split(separator: "\n").compactMap { line in
            let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard f.count >= 2, !f[0].isEmpty else { return nil }
            return EmojiEntry(emoji: f[0], name: f[1], keywords: f.count > 2 ? f[2] : "")
        }
    }
}
