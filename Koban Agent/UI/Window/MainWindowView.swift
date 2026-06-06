import SwiftUI

/// The extended window's root: a monitor, not a navigator. A toolbar and section bar over a
/// vertical split, the dense stream table beside its by-surface bars on top and the selected row's
/// provenance docked below. The panel deep-links here through the shared `MonitorModel`; the data
/// reloads from the database whenever the engine publishes (tracked through `state.revision`), so
/// an open window stays as live as the panel.
struct MainWindowView: View {
    let state: AppState
    @Bindable var model: MonitorModel
    let data: WindowDataModel
    let configurationStore: ConfigurationStore?

    private var rows: [StreamRow] {
        MonitorRowBuilder.rows(
            scope: model.scope,
            data: data.monitorData,
            surfaceFilter: model.surfaceFilter,
            searchText: model.searchText
        )
    }

    private var selectedRow: StreamRow? {
        rows.first { $0.id == model.selection }
    }

    var body: some View {
        VStack(spacing: 0) {
            MonitorToolbar(
                scope: $model.scope,
                searchText: $model.searchText,
                isShowingSettings: $model.isShowingSettings,
                showsSettingsButton: configurationStore != nil,
                isMonitoring: state.isMonitoring,
                count: rows.count,
                noun: model.scope.noun
            )
            if model.isShowingSettings, let configurationStore {
                SettingsView(store: configurationStore)
            } else {
                MonitorSectionBar(
                    scope: model.scope,
                    surfaceFilter: model.surfaceFilter,
                    onClearSurface: { model.surfaceFilter = nil }
                )
                split
            }
        }
        .frame(minWidth: Metrics.windowMinWidth, minHeight: Metrics.windowMinHeight)
        .background(Palette.bg)
        .task(id: state.revision) { await data.reload() }
        .onChange(of: model.scope) { model.selection = nil }
    }

    private var split: some View {
        VSplitView {
            HStack(spacing: 0) {
                StreamTableView(columns: model.scope.columns, rows: rows, selection: $model.selection)
                SurfaceBarsView(
                    counts: data.inventoryCountsBySurface,
                    flaggedSurfaces: data.flaggedSurfaces,
                    selected: model.surfaceFilter,
                    onSelect: toggleSurface
                )
            }
            .frame(minHeight: Metrics.streamMinHeight)
            MonitorDetailPanel(row: selectedRow, data: data)
                .frame(minHeight: Metrics.detailPanelMinHeight)
        }
    }

    private func toggleSurface(_ surface: MonitoredSurface) {
        model.surfaceFilter = model.surfaceFilter == surface ? nil : surface
    }
}
