import Foundation

/// ~/.local/state/omacos/launcher-history — "count name" per line, shared with the fzf launcher.
public struct LaunchHistory {
    public private(set) var counts: [String: Int]

    public init(counts: [String: Int] = [:]) { self.counts = counts }

    public init(text: String) {
        var c: [String: Int] = [:]
        for line in text.split(separator: "\n") {
            guard let space = line.firstIndex(of: " "), let n = Int(line[..<space]) else { continue }
            c[String(line[line.index(after: space)...])] = n
        }
        counts = c
    }

    public func count(_ name: String) -> Int { counts[name] ?? 0 }

    public mutating func bump(_ name: String) { counts[name, default: 0] += 1 }

    public var text: String {
        counts.sorted { $0.key < $1.key }.map { "\($0.value) \($0.key)" }.joined(separator: "\n") + "\n"
    }
}
