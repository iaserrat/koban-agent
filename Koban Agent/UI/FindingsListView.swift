import SwiftUI

/// The findings glance list: calm and reassuring when clear; a short ranked list of grouped
/// findings when not, with "See more" handing off to the full window section. Shared by the
/// menu-bar panel and the window's Overview; `context` sets density, the closures set behaviour.
struct FindingsListView: View {
    let findings: [Finding]
    let context: DisplayContext
    let onSeeMore: () -> Void
    let onSelect: (FindingGroup) -> Void

    private var groups: [FindingGroup] {
        FindingGroup.grouped(findings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            if groups.isEmpty {
                allClear
            } else {
                SectionLabel(title: "Findings")
                ForEach(groups.prefix(Metrics.maxFindingRows)) { group in
                    RowButton { onSelect(group) } label: {
                        FindingRow(finding: group.representative, count: group.count, context: context)
                    }
                }
                OverflowButton(shown: Metrics.maxFindingRows, total: groups.count, action: onSeeMore)
            }
        }
    }

    private var allClear: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: Symbols.allClear)
                .foregroundStyle(Palette.accent)
                .frame(width: Metrics.iconWidth)
            Text("No indicators of compromise")
                .foregroundStyle(Palette.inkMuted)
        }
        .padding(.horizontal, Metrics.rowInsetH)
    }
}
