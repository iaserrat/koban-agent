import SwiftUI

/// The bottom pane of the monitor's vertical split: the provenance of whatever row is selected
/// above. It resolves the selection back to its source record and shows the matching detail, the
/// way Red Canary docks the selected event's process tree below the stream. Nothing selected shows
/// a calm prompt rather than an empty panel.
struct MonitorDetailPanel: View {
    let row: StreamRow?
    let data: WindowDataModel

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.bg)
    }

    @ViewBuilder private var content: some View {
        if let reference = row?.reference {
            switch reference {
            case let .finding(id):
                resolvedFinding(id)
            case let .item(id, surface):
                resolvedItem(id, surface)
            }
        } else {
            empty
        }
    }

    @ViewBuilder
    private func resolvedFinding(_ id: FindingGroup.ID) -> some View {
        if let group = data.findingGroup(id: id) {
            FindingDetailView(group: group)
        } else {
            empty
        }
    }

    @ViewBuilder
    private func resolvedItem(_ id: InventoryItem.ID, _ surface: MonitoredSurface) -> some View {
        if let item = data.inventoryItem(id: id, surface: surface) {
            InventoryDetailView(item: item, data: data)
        } else {
            empty
        }
    }

    private var empty: some View {
        ContentUnavailableView(
            "Nothing selected",
            systemImage: Symbols.inventory,
            description: Text("Select a row above to trace where it came from.")
        )
    }
}
