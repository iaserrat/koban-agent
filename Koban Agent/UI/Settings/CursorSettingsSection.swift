import SwiftUI

/// Edits the Cursor configuration surface.
struct CursorSettingsSection: View {
    @Binding var settings: CursorSettings

    var body: some View {
        SettingsSection(title: "Cursor") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsTextField(label: "Global MCP path", text: $settings.globalMCPPath)
            SettingsToggleRow(label: "Include global MCP", isOn: $settings.includeGlobalMCP)
            SettingsToggleRow(label: "Include project MCP", isOn: $settings.includeProjectMCP)
            SettingsToggleRow(label: "Include rules", isOn: $settings.includeRules)
            SettingsToggleRow(label: "Include legacy rules", isOn: $settings.includeLegacyRules)
            SettingsToggleRow(label: "Include instructions", isOn: $settings.includeInstructions)
        }
    }
}
