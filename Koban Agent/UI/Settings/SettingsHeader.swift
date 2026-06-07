import SwiftUI

/// The Settings content pane's header: the active section's title and one-line summary on the left,
/// Save/Revert when there are unsaved edits, and an always-present Done that returns to the monitor.
/// The conflict banner sits above when the file changed on disk while the user had unsaved edits.
struct SettingsHeader: View {
    @Bindable var store: ConfigurationStore
    let category: SettingsCategory
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if store.externalChangeWhileEditing {
                conflictBanner
            }
            HStack(alignment: .firstTextBaseline, spacing: Metrics.spacingMedium) {
                VStack(alignment: .leading, spacing: Metrics.spacingTight) {
                    Text(category.title)
                        .font(.headline)
                        .foregroundStyle(Palette.ink)
                    Text(category.summary)
                        .font(.caption)
                        .foregroundStyle(Palette.inkSubtle)
                }
                Spacer(minLength: Metrics.spacingMedium)
                if store.isDirty {
                    Button("Revert") { store.revert() }
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.inkMuted)
                    Button("Save") { store.save() }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.accent)
                }
                Button("Done", action: onDone)
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.accent)
                    .fontWeight(.medium)
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
