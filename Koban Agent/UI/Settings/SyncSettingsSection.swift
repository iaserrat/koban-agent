import SwiftUI

/// Edits backend sync. Disabled by default; humans configure this in YAML, enrolled devices
/// receive canonical JSON over the open protocol (see koban.default.yaml).
struct SyncSettingsSection: View {
    @Binding var settings: SyncSettings
    let resetSyncState: () async throws -> Void

    @State private var isConfirmingReset = false
    @State private var isResetting = false
    @State private var resetError: String?

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
            SettingsSection(title: SyncResetLabels.sectionTitle) {
                SettingsRow(label: SyncResetLabels.identityLabel) {
                    VStack(alignment: .leading, spacing: Metrics.settingsListRowSpacing) {
                        Button(role: .destructive) {
                            isConfirmingReset = true
                        } label: {
                            Label(SyncResetLabels.buttonTitle, systemImage: Symbols.resetSync)
                        }
                        .disabled(isResetting)
                        Text(SyncResetLabels.helpText)
                            .font(.caption)
                            .foregroundStyle(Palette.inkSubtle)
                        if let resetError {
                            Text(SyncResetLabels.errorPrefix(resetError))
                                .font(.caption)
                                .foregroundStyle(Palette.critical)
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            SyncResetLabels.confirmationTitle,
            isPresented: $isConfirmingReset,
            actions: {
                Button(SyncResetLabels.confirmationButton, role: .destructive) {
                    Task { await reset() }
                }
                Button(SyncResetLabels.cancelButton, role: .cancel) {}
            },
            message: {
                Text(SyncResetLabels.confirmationMessage)
            }
        )
    }

    private func reset() async {
        isResetting = true
        resetError = nil
        do {
            try await resetSyncState()
        } catch {
            resetError = String(describing: error)
        }
        isResetting = false
    }
}
