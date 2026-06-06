import SwiftUI

/// The detail for a selected finding, laid out for the monitor's wide bottom panel: a size-led
/// header over two columns, classification and evidence on the left, the plain-language reason and
/// the per-occurrence history on the right. Reuses `DetailRow`, `EvidenceChip`, and `SectionLabel`
/// so the facts read as inspectable records, not prose (CLAUDE.md).
struct FindingDetailView: View {
    let group: FindingGroup

    private var finding: Finding {
        group.representative
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                HStack(alignment: .top, spacing: Metrics.spacingLarge) {
                    classification
                    reason
                }
                .padding(Metrics.spacingLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: finding.severity.systemImageName)
                .foregroundStyle(finding.severity.tint)
            Text(finding.title)
                .font(.title3)
                .fontWeight(.medium)
                .tracking(Metrics.headingTracking)
                .foregroundStyle(Palette.ink)
            Text(finding.itemName)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(Palette.inkMuted)
            CountBadge(count: group.count)
            Spacer()
            SeverityBadge(severity: finding.severity)
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .padding(.vertical, Metrics.spacingMedium)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private var classification: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Classification")
            DetailRow("Severity", finding.severity.label)
            DetailRow(label: "Rule") {
                Text(finding.ruleID).monospaced()
            }
            DetailRow("Surface", finding.surface.displayName)
            DetailRow("First seen", Self.timestamp(group.firstSeen))
            DetailRow("Last seen", Self.timestamp(group.lastSeen))
            DetailRow("Occurrences", String(group.count))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reason: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Why this is flagged")
            Text(finding.rationale)
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
            SectionLabel(title: "Evidence")
                .padding(.top, Metrics.spacingSmall)
            EvidenceChip(symbol: Symbols.path, value: finding.evidence.path)
            if let detail = finding.evidence.detail {
                EvidenceChip(symbol: Symbols.detail, value: detail)
            }
            if let field = finding.evidence.matchedField {
                EvidenceChip(
                    symbol: Symbols.matched,
                    value: "\(field) = \(finding.evidence.matchedValue ?? "")"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func timestamp(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
