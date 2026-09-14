import AppKit

// omacos-shell [request] — the native Panel (issue #10).
// No argument: run as the resident process (AeroSpace starts it at login).
// With a request ("launcher", "menu", "menu capture", …): hand it to the running process,
// or become that process and show it right away.

let stateDir = NSHomeDirectory() + "/.local/state/omacos"
let pidFile = stateDir + "/shell.pid"
let requestFile = stateDir + "/shell.request"
let request = CommandLine.arguments.dropFirst().joined(separator: " ")

func runningPid() -> pid_t? {
    guard let text = try? String(contentsOfFile: pidFile, encoding: .utf8), let pid = pid_t(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
    return kill(pid, 0) == 0 ? pid : nil
}

// Hand the request to the running instance: write it down, then SIGUSR1 (distributed
// notifications were not delivered reliably from a process that exits right away).
if let pid = runningPid() {
    if !request.isEmpty {
        try? request.write(toFile: requestFile, atomically: true, encoding: .utf8)
        kill(pid, SIGUSR1)
    }
    exit(0)
}

try? FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
try? String(ProcessInfo.processInfo.processIdentifier).write(toFile: pidFile, atomically: true, encoding: .utf8)

final class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: PanelController?
    let initial: String
    init(initial: String) { self.initial = initial }

    var signalSource: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = PanelController()
        self.controller = controller
        signal(SIGUSR1, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        source.setEventHandler {
            guard let req = try? String(contentsOfFile: requestFile, encoding: .utf8) else { return }
            controller.handle(request: req.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        source.resume()
        signalSource = source
        if !initial.isEmpty { controller.handle(request: initial) }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate(initial: request)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
