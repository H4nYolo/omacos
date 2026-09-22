// omacos — input jiggler for omacos-awake. Posts a tiny mouse move (optionally a click)
// into another app's window so a remote session (Citrix) never sees an idle desktop.
// Compiled once to ~/.cache/omacos/omacos-jiggle by omacos-awake.
//
// usage: omacos-jiggle --app <name> | --pid <pid>
//        [--click] [--global] [--dx <px>] [--skip-if-frontmost] [--print]
//
// Default delivery is CGEventPostToPid: the real cursor never moves, focus never
// changes, and it works while the window sits on a hidden AeroSpace workspace.
// --global posts a real event at the window centre and warps the cursor back.
// Exit: 0 posted, 1 app not running, 2 no window, 3 skipped (app is frontmost).
import AppKit

var appName: String?
var pid: pid_t?
var click = false, useGlobal = false, skipIfFrontmost = false, printOnly = false
var dx: CGFloat = 4

var args = Array(CommandLine.arguments.dropFirst())
while let arg = args.first {
    args.removeFirst()
    switch arg {
    case "--app": appName = args.first; if !args.isEmpty { args.removeFirst() }
    case "--pid": pid = args.first.flatMap { pid_t($0) }; if !args.isEmpty { args.removeFirst() }
    case "--dx": dx = args.first.flatMap { CGFloat(Double($0) ?? 4) } ?? 4; if !args.isEmpty { args.removeFirst() }
    case "--click": click = true
    case "--global": useGlobal = true
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

if useGlobal {
    let restore = CGEvent(source: nil)?.location
    for (type, point, delta) in sequence {
        event(type, point, delta: delta)?.post(tap: .cghidEventTap)
        usleep(20_000)
    }
    if let restore { CGWarpMouseCursorPosition(restore) }
} else {
    for (type, point, delta) in sequence {
        event(type, point, delta: delta)?.postToPid(target)
        usleep(20_000)
    }
}
exit(0)
