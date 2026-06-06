import SwiftUI

/// The Settings page: a category sidebar beside the selected section's form, with a header that
/// saves or reverts. Edits bind to `store.draft`; saving writes `koban.yaml` and applies it to the
/// running engine. The page is two-way synced, so an external file edit refreshes it (see
/// `ConfigurationStore`).
struct SettingsView: View {
    @Bindable var store: ConfigurationStore
    @State private var category: SettingsCategory = .watch

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $category)
            Divider().overlay(Palette.border)
            VStack(spacing: 0) {
                SettingsHeader(store: store)
                ScrollView {
                    content
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Metrics.settingsContentPadding)
                }
            }
        }
        .background(Palette.bg)
    }

    @ViewBuilder private var content: some View {
        switch category {
        case .watch:
            WatchSettingsSection(settings: $store.draft.watch)
        case .retention:
            PersistenceSettingsSection(settings: $store.draft.persistence)
        case .sync:
            SyncSettingsSection(settings: $store.draft.sync)
        case .homebrew:
            HomebrewSettingsSection(settings: $store.draft.homebrew)
        case .claude:
            ClaudeSettingsSection(settings: $store.draft.claude)
        case .codex:
            CodexSettingsSection(settings: $store.draft.codex)
        case .pi:
            PiSettingsSection(settings: $store.draft.pi)
        case .cursor:
            CursorSettingsSection(settings: $store.draft.cursor)
        case .opencode:
            OpenCodeSettingsSection(settings: $store.draft.opencode)
        case .javascript:
            JavaScriptSettingsSection(settings: $store.draft.javascript)
        case .python:
            PythonSettingsSection(settings: $store.draft.python)
        case .rules:
            RulesSettingsSection(rules: $store.draft.rules)
        }
    }
}
