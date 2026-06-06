import SwiftUI

/// An integer settings field.
struct SettingsNumberField: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        SettingsRow(label: label) {
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(Palette.ink)
                .frame(width: Metrics.settingsNumberFieldWidth)
        }
    }
}
