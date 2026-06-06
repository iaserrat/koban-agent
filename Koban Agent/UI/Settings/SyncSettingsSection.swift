import SwiftUI

/// Edits backend sync. Disabled by default; humans configure this in YAML, enrolled devices
/// receive canonical JSON over the open protocol (see koban.default.yaml).
struct SyncSettingsSection: View {
    @Binding var settings: SyncSettings

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsSectionSpacing) {
            SettingsSection(title: "Sync") {
                SettingsToggleRow(label: "Enabled", isOn: $settings.enabled)
                SettingsRow(label: "Protocol") {
                    TextField("", text: $settings.protocolName)
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(Palette.ink)
                }
                SettingsTextField(label: "Endpoint", text: $settings.endpoint)
                SettingsTextField(label: "Enrollment token", text: $settings.enrollmentToken)
                SettingsTextField(label: "Sensor token", text: $settings.sensorToken)
                SettingsTextField(label: "Tenant ID", text: $settings.tenantID)
                SettingsTextField(label: "Device ID", text: $settings.deviceID)
            }
            SettingsSection(title: "Batching and retries") {
                SettingsNumberField(label: "Max batch bytes", value: $settings.maxBatchBytes)
                SettingsNumberField(label: "Max batch events", value: $settings.maxBatchEvents)
                SettingsNumberField(label: "Check-in interval (s)", value: $settings.checkInIntervalSeconds)
                SettingsNumberField(label: "Retry base (s)", value: $settings.retryBaseSeconds)
                SettingsNumberField(label: "Retry max (s)", value: $settings.retryMaxSeconds)
                SettingsNumberField(label: "Outbox max bytes", value: $settings.outboxMaxBytes)
            }
        }
    }
}
