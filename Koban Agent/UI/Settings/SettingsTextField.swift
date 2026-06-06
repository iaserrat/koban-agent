import SwiftUI

/// An optional string settings field (a path or token), where empty means "use the built-in
/// default" (the YAML `null`). Clearing the field writes `nil`.
struct SettingsTextField: View {
    let label: String
    var placeholder: String = "Default"
    @Binding var text: String?

    private var proxy: Binding<String> {
        Binding(
            get: { text ?? "" },
            set: { text = $0.isEmpty ? nil : $0 }
        )
    }

    var body: some View {
        SettingsRow(label: label) {
            TextField(placeholder, text: proxy)
                .textFieldStyle(.roundedBorder)
                .foregroundStyle(Palette.ink)
        }
    }
}
