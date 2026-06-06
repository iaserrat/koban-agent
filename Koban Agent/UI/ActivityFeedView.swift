import SwiftUI

/// The recent-activity glance list: identical changes collapsed into counted rows, newest first,
/// with "See more" handing off to the window's full raw log. Shared by the panel and Overview.
struct ActivityFeedView: View {
    let events: [ChangeEvent]
    let context: DisplayContext
    let onSeeMore: () -> Void

    private var groups: [EventGroup] {
        EventGroup.grouped(events)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Recent activity")
            if groups.isEmpty {
                Text("No changes yet")
                    .font(.callout)
                    .foregroundStyle(Palette.inkMuted)
                    .padding(.horizontal, Metrics.rowInsetH)
            } else {
                ForEach(groups.prefix(Metrics.maxActivityRows)) { group in
                    ActivityRow(event: group.representative, count: group.count, context: context)
                        .padding(.horizontal, Metrics.rowInsetH)
                }
                OverflowButton(shown: Metrics.maxActivityRows, total: groups.count, action: onSeeMore)
            }
        }
    }
}
