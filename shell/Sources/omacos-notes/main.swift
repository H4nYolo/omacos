import AppKit

// omacos-notes [toggle|show|hide|reload] — Notes, the floating markdown scratch pad (ADR 0004).
// No argument: run as the resident process, hidden (AeroSpace starts it at login).
// With a request: hand it to the running process, or become that process and carry it out.

let stateDir = NSHomeDirectory() + "/.local/state/omacos"
let pidFile = stateDir + "/notes.pid"
let requestFile = stateDir + "/notes.request"
let request = CommandLine.arguments.dropFirst().joined(separator: " ")

func runningPid() -> pid_t? {
    guard let text = try? String(contentsOfFile: pidFile, encoding: .utf8),
          let pid = pid_t(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
    return kill(pid, 0) == 0 ? pid : nil
}

// Same hand-over as omacos-shell: write the request down, then SIGUSR1.
if let pid = runningPid() {
    if !request.isEmpty {
        try? request.write(toFile: requestFile, atomically: true, encoding: .utf8)
        kill(pid, SIGUSR1)
    }
    exit(0)
}
// a theme switch must not start Notes just to tell it about the new colours
if request == "reload" || request == "hide" { exit(0) }

try? FileManager.default.createDirectory(atPath: stateDir, withIntermediateDirectories: true)
try? String(ProcessInfo.processInfo.processIdentifier).write(toFile: pidFile, atomically: true, encoding: .utf8)

final class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: NotesController?
    var signalSource: DispatchSourceSignal?
    let initial: String
    init(initial: String) { self.initial = initial }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = NotesController()
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

    func applicationWillTerminate(_ notification: Notification) {
        controller?.model.saveAll()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate(initial: request)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
