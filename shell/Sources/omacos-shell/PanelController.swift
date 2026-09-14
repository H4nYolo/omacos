import AppKit
import SwiftUI

final class Panel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the one NSPanel: shows it centred on the monitor under the mouse, feeds key events
/// to the model and carries out the outcomes.
@MainActor
final class PanelController {
    static let size = NSSize(width: 720, height: 480)

    let panel: Panel
    let model = PanelModel()
    private var keyMonitor: Any?
    private var resignObserver: Any?

    init() {
        panel = Panel(contentRect: NSRect(origin: .zero, size: Self.size),
                      styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
                      backing: .buffered, defer: false)
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.title = "omacos-shell"
        let host = NSHostingView(rootView: PanelView(model: model))
        host.frame = NSRect(origin: .zero, size: Self.size)
        panel.contentView = host
        model.activateRequested = { [weak self] in self?.perform(self?.model.activate() ?? .keepOpen) }
        resignObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: panel, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.hide() }
        }
    }

    // MARK: requests ("launcher", "launcher --uninstall", "menu", "menu capture", "hide", anything else → Popup)

    func handle(request: String) {
        let parts = request.split(separator: " ").map(String.init)
        switch parts.first ?? "launcher" {
        case "launcher":
            toggle(.launcher(uninstall: parts.contains("--uninstall")))
        case "menu":
            let route = parts.count > 1 ? parts[1] : "root"
            toggle(.menu(path: route == "root" ? [] : [route]))
        case "emoji":
            toggle(.emoji)
        case "clipboard":
            toggle(.clipboard)
        case "keys":
            toggle(.keys(section: parts.count > 1 ? parts[1] : "all"))
        case "hide":
            hide()
        case "reload":
            model.reload()
        default:
            SystemShell.detach("omacos-popup " + SystemShell.quoted(request))
        }
    }

    private func toggle(_ mode: PanelModel.Mode) {
        if panel.isVisible && model.mode == mode { hide(); return }
        model.open(mode)
        show()
    }

    // MARK: show / hide

    func show() {
        Theme.reload()
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
        let area = screen.visibleFrame
        let size = model.mode.size
        let origin = NSPoint(x: area.midX - size.width / 2, y: area.midY - size.height / 2)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.panel.isKeyWindow else { return event }
                return self.handle(key: event) ? nil : event
            }
        }
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    private func perform(_ outcome: Outcome) {
        switch outcome {
        case .keepOpen: break
        case .hide: hide()
        case .hideThen(let action):
            hide()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { action() }
        }
    }

    // MARK: keys

    /// true = consumed
    private func handle(key event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers ?? ""
        switch event.keyCode {
        case 53: hide(); return true                                   // esc
        case 36, 76: perform(model.activate()); return true            // enter
        case 125: model.moveSelection(by: 1); return true              // down
        case 126: model.moveSelection(by: -1); return true             // up
        case 48: model.moveSelection(by: flags.contains(.shift) ? -1 : 1); return true  // tab
        case 51: perform(model.backspace()); return true               // backspace
        default: break
        }
        if flags.contains(.control) {
            switch chars {
            case "n", "j": model.moveSelection(by: 1); return true
            case "p", "k": model.moveSelection(by: -1); return true
            case "x": perform(model.secondary()); return true
            case "u": model.open(model.mode); return true
            default: return true
            }
        }
        if flags.contains(.option) && chars == "c" { perform(model.clearAll()); return true }
        if flags.contains(.command) { return false }
        if let text = event.characters, !text.isEmpty, !text.unicodeScalars.contains(where: { $0.value < 32 }) {
            model.append(text)
            return true
        }
        return true
    }
}
