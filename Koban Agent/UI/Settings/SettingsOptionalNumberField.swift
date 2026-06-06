import SwiftUI

/// An optional integer settings field, where empty means "use the built-in default" (the YAML
/// `null`). Clearing the field writes `nil`; any valid number writes that value.
struct SettingsOptionalNumberField: View {
    let label: String
    @Binding var value: Int?

    private var text: Binding<String> {
        Binding(
            get: { value.map(String.init) ?? "" },
            set: { value = Int($0) }
        )
    }

    var body: some View {
        SettingsRow(label: label) {
            TextField("Default", text: text)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(Palette.ink)
                .frame(width: Metrics.settingsNumberFieldWidth)
        }
    }
}
