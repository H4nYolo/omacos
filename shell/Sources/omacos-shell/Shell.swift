import Foundation
import OmacosCore

/// /bin/sh with the omacos PATH and without the terminal variables that confuse GUI apps.
struct SystemShell: ShellRunner {
    static let path = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

    static func environment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = path
        for key in ["TERM", "TERM_PROGRAM", "COLORTERM", "TMUX", "TMUX_PANE"] { env.removeValue(forKey: key) }
        return env
    }

    private static func process(_ command: String) -> Process {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/sh")
        p.arguments = ["-c", command]
        p.environment = environment()
        p.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
        return p
    }

    /// Run and wait; stdout trimmed.
    func run(_ command: String) -> (output: String, status: Int32) {
        let p = Self.process(command)
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice
        do { try p.run() } catch { return ("", 127) }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines), p.terminationStatus)
    }

    /// Fire and forget (menu `run` entries, popups, actions).
    static func detach(_ command: String) {
        let p = process(command)
        p.standardOutput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        p.standardInput = FileHandle.nullDevice
        try? p.run()
    }

    static func quoted(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }
}
