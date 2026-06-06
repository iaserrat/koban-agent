import SwiftUI

/// Edits the JavaScript package inventory surface.
struct JavaScriptSettingsSection: View {
    @Binding var settings: JavaScriptPackageSettings

    var body: some View {
        SettingsSection(title: "JavaScript") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsOptionalStringListEditor(label: "Project roots", items: $settings.projectRoots)
            SettingsOptionalNumberField(label: "Max depth", value: $settings.maxDepth)
            SettingsToggleRow(label: "Include npm", isOn: $settings.includeNpm)
            SettingsToggleRow(label: "Include pnpm", isOn: $settings.includePnpm)
            SettingsToggleRow(label: "Include Yarn", isOn: $settings.includeYarn)
            SettingsToggleRow(label: "Include Bun", isOn: $settings.includeBun)
            SettingsOptionalStringListEditor(
                label: "Exclude directories",
                items: $settings.excludeDirectories
            )
            SettingsStringListEditor(label: "Lockfile names", items: $settings.lockfileNames)
        }
    }
}
