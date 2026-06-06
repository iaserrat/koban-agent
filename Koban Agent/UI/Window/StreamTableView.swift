import SwiftUI

/// The monitor's hero: a dense, self-contained table that renders any scope's rows. A fixed header
/// over a lazily-built, scrollable body so it stays smooth at thousands of rows. Selection is bound
/// out to the window; the table also drives it from the keyboard (up/down) and keeps the selected
/// row scrolled into view. Built from public SwiftUI only, so the styling stays fully ours.
struct StreamTableView: View {
    let columns: [StreamColumn]
    let rows: [StreamRow]
    @Binding var selection: StreamRow.ID?

    var body: some View {
        VStack(spacing: 0) {
            StreamHeaderRow(columns: columns)
            if rows.isEmpty {
                emptyState
            } else {
                table
            }
        }
        .background(Palette.bg)
    }

    private var table: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        StreamRowView(
                            columns: columns,
                            row: row,
                            isSelected: row.id == selection,
                            onSelect: { selection = row.id }
                        )
                        .id(row.id)
                    }
                }
            }
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(.upArrow) { move(by: -1, using: proxy) }
            .onKeyPress(.downArrow) { move(by: 1, using: proxy) }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Nothing to show",
            systemImage: Symbols.shield,
            description: Text("No rows match the current scope and filters.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func move(by delta: Int, using proxy: ScrollViewProxy) -> KeyPress.Result {
        guard rows.isEmpty == false else { return .ignored }
        let current = rows.firstIndex { $0.id == selection }
        let target = current.map { min(max($0 + delta, 0), rows.count - 1) } ?? 0
        let id = rows[target].id
        selection = id
        proxy.scrollTo(id)
        return .handled
    }
}
