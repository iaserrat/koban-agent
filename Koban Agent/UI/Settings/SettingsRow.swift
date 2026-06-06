import SwiftUI

/// One labelled control in a settings form: a fixed-width leading label and trailing content.
/// Defined once so every settings field lines up identically (the one-component rule, CLAUDE.md).
struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Metrics.spacingMedium) {
            Text(label)
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
                .frame(width: Metrics.settingsLabelWidth, alignment: .leading)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
