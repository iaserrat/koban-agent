import SwiftUI

/// Edits the OpenCode configuration surface.
struct OpenCodeSettingsSection: View {
    @Binding var settings: OpenCodeSettings

    var body: some View {
        SettingsSection(title: "OpenCode") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsTextField(label: "User config directory", text: $settings.userConfigDirectory)
            SettingsOptionalStringListEditor(label: "Project roots", items: $settings.projectRoots)
            SettingsToggleRow(label: "Include global", isOn: $settings.includeGlobal)
            SettingsToggleRow(label: "Include project", isOn: $settings.includeProject)
            SettingsToggleRow(label: "Include MCP", isOn: $settings.includeMCP)
            SettingsToggleRow(label: "Include agents", isOn: $settings.includeAgents)
            SettingsToggleRow(label: "Include commands", isOn: $settings.includeCommands)
            SettingsToggleRow(label: "Include plugins", isOn: $settings.includePlugins)
            SettingsToggleRow(label: "Include instructions", isOn: $settings.includeInstructions)
            SettingsToggleRow(label: "Include managed preferences", isOn: $settings.includeManagedPreferences)
        }
    }
}
