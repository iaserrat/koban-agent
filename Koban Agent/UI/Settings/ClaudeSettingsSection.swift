import SwiftUI

/// Edits the Claude configuration surface.
struct ClaudeSettingsSection: View {
    @Binding var settings: ClaudeSettings

    var body: some View {
        SettingsSection(title: "Claude") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsTextField(label: "Config path", text: $settings.configPath)
            SettingsOptionalStringListEditor(label: "Project roots", items: $settings.projectRoots)
            SettingsToggleRow(label: "Include project MCP", isOn: $settings.includeProjectMCP)
            SettingsToggleRow(label: "Include settings", isOn: $settings.includeSettings)
            SettingsToggleRow(label: "Include agents", isOn: $settings.includeAgents)
            SettingsToggleRow(label: "Include commands", isOn: $settings.includeCommands)
            SettingsToggleRow(label: "Include hooks", isOn: $settings.includeHooks)
            SettingsToggleRow(label: "Include skills", isOn: $settings.includeSkills)
            SettingsToggleRow(label: "Include plugins", isOn: $settings.includePlugins)
            SettingsToggleRow(label: "Include instructions", isOn: $settings.includeInstructions)
            SettingsToggleRow(label: "Include managed settings", isOn: $settings.includeManagedSettings)
        }
    }
}
