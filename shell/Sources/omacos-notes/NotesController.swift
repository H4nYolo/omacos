import AppKit
import OmacosCore
import SwiftUI
import VimEngine

/// A panel that takes the keyboard without activating the app, so the app you work in stays
/// the active one and Notes can sit above it.
final class NotesPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Owns the window (ADR 0004): Liquid Glass behind the text, two opacities (with and without
/// focus), top right on the active monitor, Super+Shift+N cycling hidden → focused → hidden.
@MainActor
final class NotesController: NSObject, NSWindowDelegate, NSTextViewDelegate {
    let model = NotesModel()
    let panel: NotesPanel
    private let renderer = MarkdownRenderer()
    private let textView: NotesTextView
    private let scrollView = NSScrollView()
    private let glass: NSView
    private let tint = NSView()
    private let footer = NSTextField(labelWithString: "")
    private var tabBar: NSHostingView<TabBar>!
    private var palette: NSHostingView<Palette>?
    private var keyMonitor: Any?
    private var previewUnfocused = false
    private var previewTimer: Timer?
    private var loading = false              // swapping Tabs: not an edit

    static let radius: CGFloat = 14
    static let barHeight: CGFloat = 30

    override init() {
        NotesTheme.reload()
        let size = NSSize(width: model.state.width, height: model.state.height)
        panel = NotesPanel(contentRect: NSRect(origin: .zero, size: size),
                           styleMask: [.titled, .resizable, .fullSizeContentView, .nonactivatingPanel],
                           backing: .buffered, defer: false)
        if #available(macOS 26, *) {
            let g = NSGlassEffectView()
            g.cornerRadius = Self.radius
            glass = g
        } else {
            let v = NSVisualEffectView()
            v.material = .hudWindow
            v.blendingMode = .behindWindow
            v.state = .active
            v.wantsLayer = true
            v.layer?.cornerRadius = Self.radius
            glass = v
        }
        // zero width: autoresizing adds the scroll view's growth to the frame, a start width would count twice
        textView = NotesTextView(frame: .zero)
        super.init()
        setUpPanel()
        setUpEditor()
        setUpContent()
        model.onSwitch = { [weak self] _ in self?.loadCurrent() }
        model.onReload = { [weak self] in self?.loadCurrent(keepSelection: true) }
        model.onCreated = { [weak self] in self?.startTyping() }
        loadCurrent()
        applyOpacity()
    }

    // MARK: setup

    private func setUpPanel() {
        panel.title = "omacos-notes"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(button)?.isHidden = true
        }
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(width: 260, height: 140)
        panel.delegate = self
    }

    private func setUpEditor() {
        let storage = textView.textStorage!
        storage.delegate = renderer
        textView.layoutManager?.delegate = renderer
        renderer.layoutManager = textView.layoutManager
        renderer.fontSize = model.state.fontSize
        textView.delegate = self
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.textContainerInset = NSSize(width: 12, height: 8)
        // the usual wrapping text view: as wide as the scroll view, as tall as its text
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: textView.frame.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.vim.registerStore = PasteboardRegisterStore()
        textView.vim.onSubmodeChanged = { [weak self] in self?.updateFooter(); self?.textView.refreshCursor() }
        textView.vim.onCommandBufferChanged = { [weak self] in self?.updateFooter() }
        textView.vim.onSubmit = { [weak self] in self?.model.saveAll() }   // :w
        textView.vim.onExit = { [weak self] in self?.hide() }               // :q
        applyTheme()

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.automaticallyAdjustsContentInsets = false   // no room for the hidden title bar
    }

    private func setUpContent() {
        let root = NSView()
        root.wantsLayer = true
        panel.contentView = root
        tint.wantsLayer = true
        tint.layer?.cornerRadius = Self.radius
        tabBar = NSHostingView(rootView: TabBar(model: model, fontSize: model.state.fontSize,
                                                onTrash: { [weak self] in self?.confirmTrash($0) },
                                                onDone: { [weak self] in self?.focusEditor() },
                                                onRename: { [weak self] in self?.focusTabBar() }))
        tabBar.sizingOptions = []        // the bar must never resize the window
        footer.font = NotesTheme.font(11)
        footer.alignment = .right
        for view in [glass, tint, tabBar!, scrollView, footer] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: root.leadingAnchor), glass.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            glass.topAnchor.constraint(equalTo: root.topAnchor), glass.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            tint.leadingAnchor.constraint(equalTo: root.leadingAnchor), tint.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            tint.topAnchor.constraint(equalTo: root.topAnchor), tint.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            tabBar.leadingAnchor.constraint(equalTo: root.leadingAnchor), tabBar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: root.topAnchor, constant: 4), tabBar.heightAnchor.constraint(equalToConstant: Self.barHeight),
            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor), scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: 2),
            scrollView.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -18),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -14),
            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -4),
        ])
        updateFooter()
    }

    // MARK: requests

    func handle(request: String) {
        switch request {
        case "", "toggle": toggle()
        case "show": show()
        case "hide": hide()
        case "reload": reloadTheme()
        default: break
        }
    }

    /// hidden → show and focus · visible without focus → focus · focused → hide
    func toggle() {
        if !panel.isVisible { show() } else if !panel.isKeyWindow { focus() } else { hide() }
    }

    func show() {
        reloadTheme()
        place()
        panel.orderFrontRegardless()
        focus()
    }

    func focus() {
        panel.makeKeyAndOrderFront(nil)
        if palette == nil && model.editing == nil { focusEditor() }
        installKeyMonitor()
    }

    func hide() {
        model.saveAll()
        closePalette()
        panel.orderOut(nil)
    }

    /// Cmd+Enter: back to the app you came from, Notes stays on screen
    private func giveFocusBack() {
        model.saveAll()
        panel.orderOut(nil)
        panel.orderFrontRegardless()
    }

    private func focusEditor() {
        panel.makeFirstResponder(textView)
    }

    /// SwiftUI's focus only lands in a hosting view that is first responder; without this the
    /// name field showed up while the keys still went into the Tab.
    private func focusTabBar() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.panel.makeFirstResponder(self.tabBar)
        }
    }

    // MARK: placement

    /// Top right on the monitor that holds the focused window, below the bar like a tiled window.
    private func place() {
        let screen = activeScreen()
        let size = NSSize(width: model.state.width, height: model.state.height)
        let frame = screen.frame
        let origin = NSPoint(x: frame.maxX - 10 - size.width, y: frame.maxY - 42 - size.height)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    /// AeroSpace's focused monitor, else the one under the mouse. (The window list is no help:
    /// AeroSpace parks the windows of hidden workspaces in a corner of some monitor, and those
    /// count as on screen.)
    private func activeScreen() -> NSScreen {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
        p.arguments = ["list-monitors", "--focused", "--format", "%{monitor-name}"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = FileHandle.nullDevice
        if (try? p.run()) != nil {
            let name = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            p.waitUntilExit()
            if let screen = NSScreen.screens.first(where: { $0.localizedName == name }) { return screen }
        }
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    // MARK: look

    private func reloadTheme() {
        NotesTheme.reload()
        applyTheme()
        renderer.restyle(textView.textStorage!)
        applyOpacity()
    }

    private func applyTheme() {
        textView.font = NotesTheme.font(model.state.fontSize)
        textView.insertionPointColor = NotesTheme.accent
        textView.selectedTextAttributes = [.backgroundColor: NotesTheme.bgSelected]
        textView.typingAttributes = renderer.baseAttributes
        footer.textColor = NotesTheme.dim
    }

    /// Without focus almost only the letters are left; with focus the glass gets solid enough
    /// to write on. Cmd+Option+Plus/Minus shows the unfocused look for a moment while it changes.
    private func applyOpacity() {
        let focused = panel.isKeyWindow && !previewUnfocused
        let value = CGFloat(focused ? model.state.focusedOpacity : model.state.unfocusedOpacity)
        glass.alphaValue = min(1, value * 1.4)
        tint.layer?.backgroundColor = NotesTheme.bg.withAlphaComponent(value * 0.85).cgColor
        tabBar.alphaValue = focused ? 1 : 0.35
        footer.isHidden = !focused
        panel.hasShadow = focused
    }

    private func changeOpacity(focused: Bool, by delta: Double) {
        if focused {
            model.state.focusedOpacity = NotesState.step(model.state.focusedOpacity, by: delta)
        } else {
            model.state.unfocusedOpacity = NotesState.step(model.state.unfocusedOpacity, by: delta)
            previewUnfocused = true
            previewTimer?.invalidate()
            previewTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.previewUnfocused = false; self?.applyOpacity() }
            }
        }
        model.persist()
        applyOpacity()
        let pct = Int(((focused ? model.state.focusedOpacity : model.state.unfocusedOpacity) * 100).rounded())
        model.notice = "\(focused ? "focused" : "unfocused") \(pct) %"
    }

    private func updateFooter() {
        switch textView.vim.submode {
        case .insert: footer.stringValue = "INSERT"
        case .normal: footer.stringValue = "NORMAL"
        case .visual: footer.stringValue = "VISUAL"
        case .visualLine: footer.stringValue = "V-LINE"
        case .replace: footer.stringValue = "REPLACE"
        case .command, .search: footer.stringValue = textView.vim.badge
        }
    }

    // MARK: window events

    func windowDidBecomeKey(_ notification: Notification) { applyOpacity() }

    func windowDidResignKey(_ notification: Notification) {
        model.saveAll()
        applyOpacity()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        model.state.width = Double(panel.frame.width)
        model.state.height = Double(panel.frame.height)
        model.persist()
    }

    // MARK: text

    private func loadCurrent(keepSelection: Bool = false) {
        guard let tab = model.current, let doc = model.doc(tab) else { return }
        let old = textView.selectedRange()
        loading = true
        textView.textStorage?.replaceCharacters(in: NSRange(location: 0, length: textView.textStorage!.length), with: doc.text)
        loading = false
        let length = (doc.text as NSString).length
        let wanted = keepSelection ? old : doc.selection
        let location = min(wanted.location, length)
        textView.setSelectedRange(NSRange(location: location, length: min(wanted.length, length - location)))
        textView.scrollRangeToVisible(textView.selectedRange())
        updateRawLine()
    }

    func textDidChange(_ notification: Notification) {
        guard !loading else { return }
        model.notice = nil
        model.textChanged(textView.string, selection: textView.selectedRange())
    }

    func textViewDidChangeSelection(_ notification: Notification) {
        updateRawLine()
        if !loading { model.selectionChanged(textView.selectedRange()) }
    }

    func undoManager(for view: NSTextView) -> UndoManager? { model.undoManager(for: model.current) }

    /// the lines under the cursor (or the selection) show their markdown
    private func updateRawLine() {
        let ns = textView.string as NSString
        let selection = textView.selectedRange()
        let range = ns.length == 0 ? NSRange(location: 0, length: 0)
            : ns.paragraphRange(for: NSRange(location: min(selection.location, ns.length), length: selection.length))
        renderer.setRawRange(range, length: ns.length)
    }

    /// a fresh Tab: cursor under the heading, insert mode
    private func startTyping() {
        textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))
        if textView.vim.submode != .insert {
            textView.vim.handleKey(chars: "i", keyCode: 34, modifiers: [], editor: textView)
        }
    }

    /// Cmd+Shift+D: a timestamp heading on its own line below the cursor, then type under it
    private func insertTimestamp() {
        let ns = textView.string as NSString
        let line = ns.paragraphRange(for: NSRange(location: min(textView.selectedRange().location, ns.length), length: 0))
        let body = ns.substring(with: line).trimmingCharacters(in: .newlines)
        let stamp = NotesLibrary.timestamp()
        if body.trimmingCharacters(in: .whitespaces).isEmpty {
            textView.replace(in: NSRange(location: line.location, length: (body as NSString).length), with: stamp + "\n")
            textView.setSelectedRange(NSRange(location: line.location + (stamp as NSString).length + 1, length: 0))
        } else {
            let end = line.location + (body as NSString).length
            textView.replace(in: NSRange(location: end, length: 0), with: "\n\n" + stamp + "\n")
            textView.setSelectedRange(NSRange(location: end + 2 + (stamp as NSString).length + 1, length: 0))
        }
        if textView.vim.submode != .insert {
            textView.vim.handleKey(chars: "i", keyCode: 34, modifiers: [], editor: textView)
        }
    }

    // MARK: palette

    private func openPalette() {
        guard palette == nil, let root = panel.contentView else { return }
        let view = NSHostingView(rootView: Palette(model: model, fontSize: model.state.fontSize,
                                                   jump: { [weak self] in self?.jump(to: $0) },
                                                   close: { [weak self] in self?.closePalette() }))
        view.sizingOptions = []
        view.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            view.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12),
            view.topAnchor.constraint(equalTo: tabBar.bottomAnchor, constant: 4),
            view.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -12),
            view.heightAnchor.constraint(equalToConstant: min(320, panel.frame.height - 60)),
        ])
        palette = view
        DispatchQueue.main.async { [weak self] in self?.panel.makeFirstResponder(view) }
    }

    private func closePalette() {
        palette?.removeFromSuperview()
        palette = nil
        focusEditor()
    }

    private func jump(to hit: NotesModel.Hit) {
        closePalette()
        model.select(hit.tab)
        guard let line = hit.line else { return }
        let ns = textView.string as NSString
        var location = 0
        for _ in 0..<line where location < ns.length {
            location = NSMaxRange(ns.lineRange(for: NSRange(location: location, length: 0)))
        }
        textView.setSelectedRange(NSRange(location: min(location, ns.length), length: 0))
        textView.scrollRangeToVisible(textView.selectedRange())
    }

    // MARK: trash

    private func confirmTrash(_ tab: String) {
        let alert = NSAlert()
        alert.messageText = "Move \(tab).md to the Trash?"
        alert.informativeText = "You can put it back from the Trash in Finder."
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: panel) { [weak self] response in
            if response == .alertFirstButtonReturn { self?.model.trash(tab) }
            self?.focusEditor()
        }
    }

    // MARK: keys

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isKeyWindow else { return event }
            return self.shortcut(event) ? nil : event
        }
    }

    /// Cmd shortcuts and Ctrl+Tab; everything else goes to the focused view. true = consumed.
    private func shortcut(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if flags.contains(.control) && event.keyCode == 48 {              // ctrl+tab
            model.select(offset: flags.contains(.shift) ? -1 : 1); return true
        }
        guard flags.contains(.command) else { return false }
        let editorFocused = panel.firstResponder === textView
        let opt = flags.contains(.option), shift = flags.contains(.shift)

        if event.keyCode == 36 || event.keyCode == 76 { giveFocusBack(); return true }   // cmd+enter
        if let n = Int(key), (1...9).contains(n), !shift, !opt { model.select(number: n); return true }
        switch key {
        case "=", "+": changeOpacity(focused: !opt, by: 0.1); return true
        case "-": changeOpacity(focused: !opt, by: -0.1); return true
        case "t": closePalette(); model.editing = .new; focusTabBar(); return true
        case "w": if let c = model.current { model.close(c) }; return true
        case "p": palette == nil ? openPalette() : closePalette(); return true
        case "e": editInNvim(); return true
        case "s": model.saveAll(); return true
        case "d" where shift && editorFocused: insertTimestamp(); return true
        case "x" where shift && editorFocused: textView.toggleTask(); return true
        default: break
        }
        // no main menu in an accessory app: the standard edit keys go to whoever has the focus
        let target = panel.firstResponder
        let action: Selector?
        switch key {
        case "c": action = #selector(NSText.copy(_:))
        case "v": action = #selector(NSText.paste(_:))
        case "x": action = #selector(NSText.cut(_:))
        case "a": action = #selector(NSText.selectAll(_:))
        case "z": action = shift ? Selector(("redo:")) : Selector(("undo:"))
        default: action = nil
        }
        if let action, NSApp.sendAction(action, to: target, from: nil) { return true }
        return false
    }

    /// Cmd+E: the current Tab in real nvim in the Popup; Notes steps aside and reloads afterwards.
    /// Sent through omacos-shell, which forwards unknown requests to the Popup: firing the Popup
    /// goes through System Events, and the Panel already holds that permission.
    private func editInNvim() {
        guard let tab = model.current else { return }
        hide()
        let p = Process()
        p.executableURL = URL(fileURLWithPath: NSHomeDirectory() + "/.local/bin/omacos-shell")
        p.arguments = ["notes-edit", model.url(of: tab).path]
        try? p.run()
    }
}
