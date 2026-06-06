import SwiftUI

/// Edits on-disk history retention.
struct PersistenceSettingsSection: View {
    @Binding var settings: PersistenceSettings

    var body: some View {
        SettingsSection(title: "Retention") {
            SettingsNumberField(label: "Max stored events", value: $settings.maxStoredEvents)
            SettingsNumberField(label: "Max stored findings", value: $settings.maxStoredFindings)
        }
    }
}
