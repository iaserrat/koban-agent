import SwiftUI

/// Edits the Codex configuration surface.
struct CodexSettingsSection: View {
    @Binding var settings: CodexSettings

    var body: some View {
        SettingsSection(title: "Codex") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsTextField(label: "User config path", text: $settings.userConfigPath)
            SettingsTextField(label: "Profile config glob", text: $settings.profileConfigGlob)
            SettingsOptionalStringListEditor(label: "Project roots", items: $settings.projectRoots)
            SettingsToggleRow(label: "Include system config", isOn: $settings.includeSystemConfig)
            SettingsToggleRow(label: "Include skills", isOn: $settings.includeSkills)
            SettingsToggleRow(label: "Include hooks", isOn: $settings.includeHooks)
            SettingsToggleRow(label: "Include rules", isOn: $settings.includeRules)
        }
    }
}
