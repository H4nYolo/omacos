import SwiftUI

private extension NSColor { var ui: Color { Color(nsColor: self) } }

// SwiftUI's @State is a macro whose plugin ships with Xcode only; with the Command Line Tools
// view state lives in small ObservableObjects instead (same as the Panel).
private final class TextBox: ObservableObject {
    @Published var text: String
    init(_ text: String) { self.text = text }
}

private final class PaletteState: ObservableObject {
    @Published var query = ""
    @Published var hits: [NotesModel.Hit] = []
    @Published var selected = 0
}

/// The thin row of Tab names on top: click switches, double-click renames, drag reorders, the
/// context menu closes or trashes. Cmd+T shows a name field at the end.
struct TabBar: View {
    @ObservedObject var model: NotesModel
    var fontSize: CGFloat
    var onTrash: (String) -> Void
    var onDone: () -> Void          // name field finished: back to the editor
    var onRename: () -> Void        // name field opened: the keys must go to it

    var body: some View {
        HStack(spacing: 14) {
            ForEach(Array(model.tabs.enumerated()), id: \.element) { index, tab in
                if model.editing == .rename(tab) {
                    NameField(initial: tab, fontSize: fontSize, commit: commit, cancel: cancel)
                } else {
                    label(tab, index: index)
                }
            }
            if model.editing == .new {
                NameField(initial: "", fontSize: fontSize, commit: commit, cancel: cancel)
            }
            Spacer(minLength: 0)
            if let notice = model.notice {
                Text(notice).font(.custom(NotesTheme.fontName, size: fontSize - 2)).foregroundColor(NotesTheme.dim.ui).lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30, alignment: .leading)
        .ignoresSafeArea()      // the hidden title bar is ours to draw on
    }

    private func label(_ tab: String, index: Int) -> some View {
        let isCurrent = tab == model.current
        return Text(tab)
            .font(.custom(NotesTheme.fontName, size: fontSize - 1).weight(isCurrent ? .bold : .regular))
            .foregroundColor(isCurrent ? NotesTheme.accent.ui : NotesTheme.dim.ui)
            .lineLimit(1)
            .padding(.vertical, 3)
            .overlay(alignment: .bottom) {
                if isCurrent { Rectangle().fill(NotesTheme.accent.ui).frame(height: 1.5) }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { model.editing = .rename(tab); onRename() }
            .onTapGesture { model.select(tab); onDone() }
            .draggable(tab)
            .dropDestination(for: String.self) { items, _ in
                guard let dragged = items.first else { return false }
                model.move(dragged, before: tab)
                return true
            }
            .contextMenu {
                Button("Rename") { model.editing = .rename(tab); onRename() }
                Button("Close Tab") { model.close(tab) }
                Divider()
                Button("Move to Trash…") { onTrash(tab) }
            }
    }

    private func commit(_ text: String) { model.commitEditing(text); onDone() }
    private func cancel() { model.editing = nil; onDone() }
}

private struct NameField: View {
    @StateObject private var box: TextBox
    let fontSize: CGFloat
    let commit: (String) -> Void
    let cancel: () -> Void
    @FocusState private var focused: Bool

    init(initial: String, fontSize: CGFloat, commit: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        _box = StateObject(wrappedValue: TextBox(initial))
        self.fontSize = fontSize
        self.commit = commit
        self.cancel = cancel
    }

    var body: some View {
        TextField("name", text: $box.text)
            .textFieldStyle(.plain)
            .font(.custom(NotesTheme.fontName, size: fontSize - 1))
            .foregroundColor(NotesTheme.fg.ui)
            .frame(width: 140)
            .focused($focused)
            .onSubmit { commit(box.text) }
            .onExitCommand { cancel() }
            .onAppear { DispatchQueue.main.async { focused = true } }
    }
}

/// Cmd+P: fuzzy over Tab names and every line of every Tab; Enter jumps to the Tab and line.
struct Palette: View {
    @ObservedObject var model: NotesModel
    var fontSize: CGFloat
    var jump: (NotesModel.Hit) -> Void
    var close: () -> Void

    @StateObject private var ui = PaletteState()
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Tab or text…", text: $ui.query)
                .textFieldStyle(.plain)
                .font(.custom(NotesTheme.fontName, size: fontSize))
                .foregroundColor(NotesTheme.fg.ui)
                .padding(10)
                .focused($focused)
                .onSubmit { if ui.hits.indices.contains(ui.selected) { jump(ui.hits[ui.selected]) } }
                .onExitCommand { close() }
                .onKeyPress(.downArrow) { move(1) }
                .onKeyPress(.upArrow) { move(-1) }
                .onKeyPress(keys: ["n", "j"]) { press in press.modifiers.contains(.control) ? move(1) : .ignored }
                .onKeyPress(keys: ["p", "k"]) { press in press.modifiers.contains(.control) ? move(-1) : .ignored }
            Rectangle().fill(NotesTheme.border.ui).frame(height: 1)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(ui.hits) { hit in
                            Text(hit.label)
                                .font(.custom(NotesTheme.fontName, size: fontSize - 1))
                                .foregroundColor(hit.id == ui.selected ? NotesTheme.fg.ui : (hit.line == nil ? NotesTheme.accent.ui : NotesTheme.dim.ui))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10).padding(.vertical, 3)
                                .background(hit.id == ui.selected ? NotesTheme.bgSelected.ui : Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { jump(hit) }
                                .id(hit.id)
                        }
                    }
                }
                .onChange(of: ui.selected) { _, id in proxy.scrollTo(id) }
            }
        }
        .background(NotesTheme.bg.ui.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(NotesTheme.border.ui, lineWidth: 1))
        .onAppear { ui.hits = model.search(""); DispatchQueue.main.async { focused = true } }
        .onChange(of: ui.query) { _, q in ui.hits = model.search(q); ui.selected = 0 }
    }

    private func move(_ by: Int) -> KeyPress.Result {
        guard !ui.hits.isEmpty else { return .handled }
        ui.selected = (ui.selected + by + ui.hits.count) % ui.hits.count
        return .handled
    }
}
