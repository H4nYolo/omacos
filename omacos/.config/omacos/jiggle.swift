// omacos — input jiggler for omacos-awake. Posts a tiny mouse move (optionally a click)
// into another app's window so a remote session (Citrix) never sees an idle desktop.
// Compiled once to ~/.cache/omacos/omacos-jiggle by omacos-awake.
//
// usage: omacos-jiggle --app <name> | --pid <pid>
//        [--click] [--key] [--global] [--activate] [--settle <ms>] [--dx <px>]
//        [--skip-if-frontmost] [--print]
//
// Three ways in, quiet to loud — a remote viewer only forwards what its own event
// handling actually sees, so which one works is a per-app question:
//   (default)  CGEventPostToPid: cursor stays, focus stays, hidden workspaces fine.
//              AppKit drops these unless the app has a key window, i.e. is active.
//   --global   a real event at the window centre, cursor warped back afterwards.
//              Reaches apps that watch the event stream with a tap instead.
//   --activate front app is remembered, the target is activated for a moment, the
//              event goes in, the old app is activated again. Costs ~0.2 s of focus.
// --key adds an F15 press (invisible in Windows, still counts as input there).
// Exit: 0 posted, 1 app not running, 2 no window, 3 skipped (app is frontmost),
//       4 window parked off-screen (hidden workspace) and --global needs it visible,
//       5 the app could not be activated.
import AppKit

var appName: String?
var pid: pid_t?
var click = false, useGlobal = false, skipIfFrontmost = false, printOnly = false
var sendKey = false, activate = false
var settle: UInt32 = 1_000_000        // µs to wait for the activation to land
var dx: CGFloat = 4

var args = Array(CommandLine.arguments.dropFirst())
while let arg = args.first {
    args.removeFirst()
    switch arg {
    case "--app": appName = args.first; if !args.isEmpty { args.removeFirst() }
    case "--pid": pid = args.first.flatMap { pid_t($0) }; if !args.isEmpty { args.removeFirst() }
    case "--dx": dx = args.first.flatMap { CGFloat(Double($0) ?? 4) } ?? 4; if !args.isEmpty { args.removeFirst() }
    case "--click": click = true
    case "--key": sendKey = true
    case "--global": useGlobal = true
    case "--activate": activate = true
    case "--settle":
        settle = UInt32((args.first.flatMap { Double($0) } ?? 1000) * 1000)
        if !args.isEmpty { args.removeFirst() }
    case "--skip-if-frontmost": skipIfFrontmost = true
    case "--print": printOnly = true
    default:
        FileHandle.standardError.write("omacos-jiggle: unknown option \(arg)\n".data(using: .utf8)!)
        exit(64)
    }
}

func die(_ message: String, _ code: Int32) -> Never {
    FileHandle.standardError.write("omacos-jiggle: \(message)\n".data(using: .utf8)!)
    exit(code)
}

if pid == nil, let name = appName {
    let hit = NSWorkspace.shared.runningApplications.first {
        $0.localizedName == name || $0.bundleURL?.deletingPathExtension().lastPathComponent == name
    }
    pid = hit?.processIdentifier
}
guard let target = pid else { die("app not running", 1) }

if skipIfFrontmost, NSWorkspace.shared.frontmostApplication?.processIdentifier == target { exit(3) }

// Largest normal-layer window of that process. Offscreen windows count: AeroSpace parks
// the windows of a hidden workspace far outside the displays, and the session still ticks.
let info = (CGWindowListCopyWindowInfo([.excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
let rects: [CGRect] = info.compactMap { window in
    guard window[kCGWindowOwnerPID as String] as? pid_t == target,
          window[kCGWindowLayer as String] as? Int == 0,
          let bounds = window[kCGWindowBounds as String] as? [String: Any],
          let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { return nil }
    return rect
}
guard let frame = rects.max(by: { $0.width * $0.height < $1.width * $1.height }), frame.width > 1 else {
    die("no window", 2)
}

let centre = CGPoint(x: frame.midX, y: frame.midY)
let nudged = CGPoint(x: frame.midX + dx, y: frame.midY)

if printOnly {
    print("pid=\(target) window=\(Int(frame.origin.x)),\(Int(frame.origin.y)) \(Int(frame.width))x\(Int(frame.height)) centre=\(Int(centre.x)),\(Int(centre.y))")
    exit(0)
}

// A remote viewer usually forwards relative motion, so the deltas matter as much as the
// position; an HID-state source keeps the event indistinguishable from a real mouse.
let source = CGEventSource(stateID: .hidSystemState)

func event(_ type: CGEventType, _ point: CGPoint, delta: CGFloat = 0) -> CGEvent? {
    let e = CGEvent(mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: .left)
    e?.setIntegerValueField(.mouseEventClickState, value: 1)
    e?.setIntegerValueField(.mouseEventDeltaX, value: Int64(delta))
    e?.setIntegerValueField(.mouseEventDeltaY, value: 0)
    return e
}

var sequence: [(CGEventType, CGPoint, CGFloat)] = [(.mouseMoved, nudged, dx), (.mouseMoved, centre, -dx)]
if click { sequence += [(.leftMouseDown, centre, 0), (.leftMouseUp, centre, 0)] }

// Both loud modes need the window to be where the user can see it: AeroSpace parks the
// windows of a hidden workspace far outside every display (verified: x = 5749 for a window
// on workspace 1 while workspace 4 was visible), and activating one would drag that whole
// workspace onto the monitor in front of the user.
if useGlobal || activate {
    let onScreen = NSScreen.screens.contains { screen in
        var frame = screen.frame
        // NSScreen is bottom-left based, CGWindow/CGEvent are top-left based
        if let primary = NSScreen.screens.first {
            frame.origin.y = primary.frame.maxY - frame.maxY
        }
        return frame.insetBy(dx: -1, dy: -1).contains(CGPoint(x: centre.x, y: centre.y))
    }
    if !onScreen { die("window is off-screen (its workspace is not visible)", 4) }
}

let previous = activate ? NSWorkspace.shared.frontmostApplication : nil

// Always hand the focus back, including when the activation itself went wrong:
// leaving it on the remote session would be worse than not nudging at all.
func restoreFocus() {
    guard let previous, previous.processIdentifier != target else { return }
    usleep(40_000)
    previous.activate()
}

if activate {
    guard let app = NSRunningApplication(processIdentifier: target) else { die("app not running", 1) }
    app.activate()
    // NSWorkspace learns about the new front app from a notification, so the run loop
    // has to turn while we wait — a plain usleep() would still see the old value.
    var waited: UInt32 = 0
    while waited < settle, NSWorkspace.shared.frontmostApplication?.processIdentifier != target {
        RunLoop.current.run(until: Date().addingTimeInterval(0.01)); waited += 10_000
    }
    if NSWorkspace.shared.frontmostApplication?.processIdentifier != target {
        restoreFocus()
        die("could not activate the app", 5)
    }
}

func send(_ event: CGEvent?) {
    guard let event else { return }
    if useGlobal { event.post(tap: .cghidEventTap) } else { event.postToPid(target) }
    usleep(20_000)
}

let restore = useGlobal ? CGEvent(source: nil)?.location : nil
for (type, point, delta) in sequence { send(event(type, point, delta: delta)) }
if sendKey {
    let f15: CGKeyCode = 0x71
    send(CGEvent(keyboardEventSource: source, virtualKey: f15, keyDown: true))
    send(CGEvent(keyboardEventSource: source, virtualKey: f15, keyDown: false))
}
if let restore { CGWarpMouseCursorPosition(restore) }

restoreFocus()
exit(0)
