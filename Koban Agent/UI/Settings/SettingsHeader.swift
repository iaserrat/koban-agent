import SwiftUI

/// The Settings content pane's header: the dirty-state hint with Save/Revert, and the conflict
/// banner shown when the file changed on disk while the user had unsaved edits.
struct SettingsHeader: View {
    @Bindable var store: ConfigurationStore

    var body: some View {
        VStack(spacing: 0) {
            if store.externalChangeWhileEditing {
                conflictBanner
            }
            HStack(spacing: Metrics.spacingMedium) {
                if store.isDirty {
                    Text("Unsaved changes")
                        .font(.caption)
                        .foregroundStyle(Palette.inkSubtle)
                }
                Spacer()
                Button("Revert") { store.revert() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.inkMuted)
                    .disabled(store.isDirty == false)
                Button("Save") { store.save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.accent)
                    .disabled(store.isDirty == false)
            }
            .padding(.horizontal, Metrics.settingsContentPadding)
            .padding(.vertical, Metrics.spacingMedium)
            Divider().overlay(Palette.border)
        }
    }

    private var conflictBanner: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: Symbols.warning)
                .foregroundStyle(Palette.alert)
            Text("The configuration file changed on disk.")
                .font(.caption)
                .foregroundStyle(Palette.ink)
            Spacer()
            Button("Reload") { store.revert() }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accent)
            Button("Keep mine") { store.keepDraftOverExternalChange() }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.inkMuted)
        }
        .padding(.horizontal, Metrics.settingsContentPadding)
        .padding(.vertical, Metrics.spacingSmall)
        .background(Palette.surface)
    }
}
