import SwiftUI

/// Edits the watch-pipeline timing and discovery settings.
struct WatchSettingsSection: View {
    @Binding var settings: WatchSettings

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsSectionSpacing) {
            SettingsSection(title: "Timing") {
                SettingsNumberField(label: "Debounce (ms)", value: $settings.debounceMilliseconds)
                SettingsNumberField(label: "Poll interval (s)", value: $settings.pollIntervalSeconds)
                SettingsNumberField(
                    label: "Max scan wall-clock (s)",
                    value: $settings.maxScanWallClockSeconds
                )
                SettingsNumberField(label: "Max fresh scan age (s)", value: $settings.maxFreshScanAgeSeconds)
            }
            SettingsSection(title: "Project discovery") {
                SettingsStringListEditor(label: "Project roots", items: $settings.projectDiscovery.roots)
                SettingsNumberField(label: "Max depth", value: $settings.projectDiscovery.maxDepth)
                SettingsStringListEditor(
                    label: "Exclude directories",
                    items: $settings.projectDiscovery.excludeDirectories
                )
            }
            HomeSignalScanSettingsSection(settings: $settings.homeSignalScan)
        }
    }
}
