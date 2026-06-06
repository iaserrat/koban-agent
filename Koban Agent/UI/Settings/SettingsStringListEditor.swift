import SwiftUI

/// Edits a list of strings (paths, file names, globs): one text field per entry with a remove
/// button, and an add button. Indices key the rows, so duplicate or empty entries are allowed
/// while typing.
struct SettingsStringListEditor: View {
    let label: String
    @Binding var items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsListRowSpacing) {
            Text(label)
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
            ForEach(items.indices, id: \.self) { index in
                HStack(spacing: Metrics.spacingSmall) {
                    TextField("", text: $items[index])
                        .textFieldStyle(.roundedBorder)
                        .foregroundStyle(Palette.ink)
                    Button {
                        items.remove(at: index)
                    } label: {
                        Image(systemName: Symbols.removeItem)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Palette.inkSubtle)
                }
            }
            Button {
                items.append("")
            } label: {
                Label("Add", systemImage: Symbols.addItem)
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.accent)
        }
    }
}
