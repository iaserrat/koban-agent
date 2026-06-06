import SwiftUI

/// Edits the Python dependency inventory surface.
struct PythonSettingsSection: View {
    @Binding var settings: PythonPackageSettings

    var body: some View {
        SettingsSection(title: "Python") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsOptionalStringListEditor(label: "Project roots", items: $settings.projectRoots)
            SettingsOptionalNumberField(label: "Max depth", value: $settings.maxDepth)
            SettingsToggleRow(label: "Include uv", isOn: $settings.includeUV)
            SettingsToggleRow(label: "Include pyproject", isOn: $settings.includePyProject)
            SettingsToggleRow(label: "Include requirements", isOn: $settings.includeRequirements)
            SettingsToggleRow(label: "Include pylock", isOn: $settings.includePylock)
            SettingsOptionalStringListEditor(
                label: "Exclude directories",
                items: $settings.excludeDirectories
            )
            SettingsStringListEditor(label: "Requirement file globs", items: $settings.requirementFileGlobs)
        }
    }
}
