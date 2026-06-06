import SwiftUI

/// Edits the opt-in home-directory signal scan, nested under Watch.
struct HomeSignalScanSettingsSection: View {
    @Binding var settings: HomeSignalScanSettings

    var body: some View {
        SettingsSection(title: "Home signal scan") {
            SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
            SettingsRow(label: "Root") {
                TextField("", text: $settings.root)
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Palette.ink)
            }
            SettingsNumberField(label: "Max depth", value: $settings.maxDepth)
            SettingsToggleRow(label: "Follow symlinks", isOn: $settings.followSymlinks)
            SettingsToggleRow(label: "Event path filtering", isOn: $settings.eventPathFiltering)
            SettingsNumberField(
                label: "Budget: max directories",
                value: $settings.initialScanBudget.maxDirectoriesVisited
            )
            SettingsNumberField(
                label: "Budget: max files",
                value: $settings.initialScanBudget.maxFilesVisited
            )
            SettingsNumberField(
                label: "Budget: max seconds",
                value: $settings.initialScanBudget.maxWallClockSeconds
            )
            SettingsStringListEditor(label: "Signal file names", items: $settings.signalFileNames)
            SettingsStringListEditor(label: "Signal file globs", items: $settings.signalFileGlobs)
            SettingsStringListEditor(label: "Prune directory names", items: $settings.pruneDirectoryNames)
        }
    }
}
