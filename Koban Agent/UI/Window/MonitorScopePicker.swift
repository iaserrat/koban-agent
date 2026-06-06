import SwiftUI

/// The toolbar's scope control: a custom segmented switch between Activity, Findings, and
/// Inventory. The selected segment carries the Fleet Violet wash that marks selection everywhere
/// else in the window, so the whole UI reads from one accent. Built custom for that exact styling;
/// the native segmented picker can't take it.
struct MonitorScopePicker: View {
    @Binding var scope: MonitorScope

    var body: some View {
        HStack(spacing: Metrics.spacingTight) {
            ForEach(MonitorScope.allCases) { option in
                segment(option)
            }
        }
        .padding(Metrics.segmentInset)
        .background(
            RoundedRectangle(cornerRadius: Metrics.segmentGroupCornerRadius, style: .continuous)
                .fill(Palette.bgDeep)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.segmentGroupCornerRadius, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
        )
    }

    private func segment(_ option: MonitorScope) -> some View {
        let isSelected = scope == option
        return Button {
            scope = option
        } label: {
            Text(option.label)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? Palette.ink : Palette.inkMuted)
                .padding(.horizontal, Metrics.segmentPaddingH)
                .padding(.vertical, Metrics.segmentPaddingV)
                .background(segmentBackground(isSelected))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func segmentBackground(_ isSelected: Bool) -> some View {
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
