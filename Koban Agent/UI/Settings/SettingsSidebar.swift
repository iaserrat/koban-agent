import SwiftUI

/// The Settings page's category list. A vertical analogue of the toolbar's scope picker: the
/// selected row carries the same Fleet Violet wash that marks selection across the window.
struct SettingsSidebar: View {
    @Binding var selection: SettingsCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.spacingTight) {
                ForEach(SettingsCategory.allCases) { category in
                    row(category)
                }
            }
            .padding(Metrics.panelPadding)
        }
        .frame(width: Metrics.settingsSidebarWidth)
        .background(Palette.bgDeep)
    }

    private func row(_ category: SettingsCategory) -> some View {
        let isSelected = selection == category
        return Button {
            selection = category
        } label: {
            Text(category.title)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Palette.ink : Palette.inkMuted)
                .padding(.horizontal, Metrics.chipPaddingH)
                .padding(.vertical, Metrics.segmentPaddingV)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(background(isSelected))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func background(_ isSelected: Bool) -> some View {
        if isSelected {
            RoundedRectangle(cornerRadius: Metrics.rowCornerRadius, style: .continuous)
                .fill(Palette.accentSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.rowCornerRadius, style: .continuous)
                        .strokeBorder(Palette.borderStrong, lineWidth: Metrics.hairline)
                )
        }
    }
}
