import SwiftUI

/// Edits an optional string list, where `nil` means "use the built-in default". A toggle chooses
/// between the default and an explicit list; turning it on seeds an empty (editable) list.
struct SettingsOptionalStringListEditor: View {
    let label: String
    @Binding var items: [String]?

    private var isExplicit: Binding<Bool> {
        Binding(
            get: { items != nil },
            set: { explicit in items = explicit ? (items ?? []) : nil }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsListRowSpacing) {
            SettingsToggleRow(label: "Set \(label) explicitly", isOn: isExplicit)
            if items != nil {
                SettingsStringListEditor(
                    label: label,
                    items: Binding(get: { items ?? [] }, set: { items = $0 })
                )
            } else {
                Text("Using built-in default.")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSubtle)
            }
        }
    }
}
