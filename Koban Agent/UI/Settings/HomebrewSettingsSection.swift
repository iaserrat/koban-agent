import SwiftUI

/// Edits the Homebrew surface.
struct HomebrewSettingsSection: View {
    @Binding var settings: HomebrewSettings

    var body: some View {
        SettingsSection(title: "Homebrew") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsOptionalStringListEditor(label: "Prefixes", items: $settings.prefixes)
        }
    }
}
