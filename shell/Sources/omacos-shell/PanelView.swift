import SwiftUI

struct PanelView: View {
    @ObservedObject var model: PanelModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(model.prompt).foregroundColor(Theme.accent)
                Text(model.query).foregroundColor(Theme.fg)
                Rectangle().fill(Theme.fg).frame(width: 8, height: 17).opacity(0.9)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

            Rectangle().fill(Theme.border).frame(height: 1).padding(.horizontal, 12)

            HStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(model.rows) { row in
                                RowView(row: row, selected: row.id == model.selected)
                                    .id(row.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture { model.selected = row.id; model.activateRequested?() }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onChange(of: model.selected) { _, new in proxy.scrollTo(new) }
                    .onChange(of: model.rows.count) { _, _ in proxy.scrollTo(0) }
                }
                if model.mode.hasPreview {
                    Rectangle().fill(Theme.border).frame(width: 1).padding(.vertical, 8)
                    ScrollView(showsIndicators: false) {
                        Text(model.preview)
                            .font(Theme.font(13)).foregroundColor(Theme.fg)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(12)
                    }
                    .frame(width: 400)
                }
            }

            Text(model.footer)
                .font(Theme.font(12)).foregroundColor(Theme.dim)
                .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .font(Theme.font(15))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RowView: View {
    let row: Row
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            switch row.icon {
            case .glyph(let g): Text(g).foregroundColor(selected ? Theme.fg : Theme.accent).frame(width: 24, alignment: .center)
            case .image(let img): Image(nsImage: img).resizable().frame(width: 20, height: 20).frame(width: 24, alignment: .center)
            case .none: EmptyView()
            }
            Text(row.label).foregroundColor(Theme.fg).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, 4)
        .background(selected ? Theme.bgSelected : Color.clear)
        .cornerRadius(4)
        .padding(.horizontal, 8)
    }
}
