import Foundation

/// The launcher's matching, same rules as `fzf --exact` in the Popup: every whitespace-separated
/// word of the query must occur as a substring (case-insensitive). Word starts score higher, earlier
/// matches score higher, then the launch history decides, then the name.
public enum Matcher {
    public struct Scored<T> {
        public let item: T
        public let score: Int
    }

    /// nil = no match; otherwise a score, higher is better.
    public static func score(query: String, label: String) -> Int? {
        let words = query.lowercased().split(whereSeparator: { $0 == " " }).map(String.init)
        if words.isEmpty { return 0 }
        let hay = label.lowercased()
        var total = 0
        for word in words {
            guard let range = hay.range(of: word) else { return nil }
            let offset = hay.distance(from: hay.startIndex, to: range.lowerBound)
            var s = 100 - min(offset, 50)
            if offset == 0 { s += 60 }                                  // label starts with the word
            else if hay[hay.index(before: range.lowerBound)] == " " { s += 40 }  // a word starts with it
            if word.count == hay.count { s += 30 }                       // exact
            total += s
        }
        return total
    }

    /// Filter + order. `rank` breaks ties (higher first), then the label alphabetically.
    public static func rank<T>(_ items: [T], query: String, label: (T) -> String, rank: (T) -> Int = { _ in 0 }) -> [T] {
        let scored: [(T, Int, Int, String)] = items.compactMap { item in
            guard let s = score(query: query, label: label(item)) else { return nil }
            return (item, s, rank(item), label(item).lowercased())
        }
        return scored.sorted { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            if a.2 != b.2 { return a.2 > b.2 }
            return a.3 < b.3
        }.map { $0.0 }
    }
}
