import SwiftUI

/// The Settings page's category list: grouped blocks (Pipeline, Ecosystems, Rules), each row an
/// icon beside its title. The selected row carries the same Fleet Violet wash that marks selection
/// across the window, and its icon lights up as the cue.
struct SettingsSidebar: View {
    @Binding var selection: SettingsCategory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.settingsSectionSpacing) {
                ForEach(SettingsCategoryGroup.allCases) { group in
                    section(group)
                }
            }
            .padding(Metrics.panelPadding)
        }
        .frame(width: Metrics.settingsSidebarWidth)
        .background(Palette.bgDeep)
    }

    private func section(_ group: SettingsCategoryGroup) -> some View {
        VStack(alignment: .leading, spacing: Metrics.spacingTight) {
            SectionLabel(title: group.title)
                .padding(.horizontal, Metrics.rowInsetH)
                .padding(.bottom, Metrics.spacingTight)
            ForEach(SettingsCategory.allCases.filter { $0.group == group }) { category in
                row(category)
            }
        }
    }

    private func row(_ category: SettingsCategory) -> some View {
        let isSelected = selection == category
        return Button {
            selection = category
        } label: {
            HStack(spacing: Metrics.spacingSmall) {
                SettingsCategoryIconView(icon: category.icon, isSelected: isSelected)
                Text(category.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? Palette.ink : Palette.inkMuted)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Metrics.rowInsetH)
            .padding(.vertical, Metrics.rowInsetV)
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
