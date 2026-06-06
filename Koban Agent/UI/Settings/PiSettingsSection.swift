import SwiftUI

/// Edits the Pi configuration surface.
struct PiSettingsSection: View {
    @Binding var settings: PiSettings

    var body: some View {
        SettingsSection(title: "Pi") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsTextField(label: "Agent directory", text: $settings.agentDirectory)
            SettingsToggleRow(label: "Include shared global MCP", isOn: $settings.includeSharedGlobalMCP)
            SettingsToggleRow(label: "Include shared project MCP", isOn: $settings.includeSharedProjectMCP)
            SettingsToggleRow(label: "Include Pi global override", isOn: $settings.includePiGlobalOverride)
            SettingsToggleRow(label: "Include Pi project override", isOn: $settings.includePiProjectOverride)
            SettingsToggleRow(label: "Include packages", isOn: $settings.includePackages)
            SettingsToggleRow(label: "Include imports", isOn: $settings.includeImports)
        }
    }
}
