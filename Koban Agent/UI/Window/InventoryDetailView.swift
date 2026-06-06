import SwiftUI

/// The detail for a selected inventory item, laid out for the monitor's wide bottom panel: a header
/// over two columns, reconstructed provenance on the left, the findings raised against it and its
/// recent changes on the right. Ties inventory to findings to activity, the provenance story the
/// product tells. Reuses `FindingRow`/`ActivityRow` rather than restating them (CLAUDE.md).
struct InventoryDetailView: View {
    let item: InventoryItem
    let data: WindowDataModel

    private var relatedFindings: [Finding] {
        data.findings(for: item)
    }

    private var relatedActivity: [ChangeEvent] {
        data.activity(for: item)
    }

    private var worstSeverity: Severity? {
        relatedFindings.map(\.severity).max()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                HStack(alignment: .top, spacing: Metrics.spacingLarge) {
                    provenance
                    related
                }
                .padding(Metrics.spacingLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: item.id) { await data.loadDetail(for: item) }
    }

    private var header: some View {
        HStack(spacing: Metrics.spacingSmall) {
            MonogramChip(surface: item.surface, isHighlighted: true)
            Text(item.name)
                .font(.title3)
                .fontWeight(.medium)
                .tracking(Metrics.headingTracking)
                .foregroundStyle(Palette.ink)
            if let version = item.version {
                Text(version)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(Palette.inkMuted)
            }
            Spacer()
            if let worstSeverity {
                SeverityBadge(severity: worstSeverity)
            }
        }
        .padding(.horizontal, Metrics.spacingLarge)
        .padding(.vertical, Metrics.spacingMedium)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private var provenance: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            SectionLabel(title: "Provenance")
            DetailRow("Surface", item.surface.displayName)
            DetailRow("Origin", item.provenance.origin)
            EvidenceChip(symbol: Symbols.path, value: item.path)
            if let detail = item.provenance.detail {
                EvidenceChip(symbol: Symbols.detail, value: detail)
            }
            if let onRequest = item.provenance.installedOnRequest {
                DetailRow("Installed on request", onRequest ? "Yes" : "No")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var related: some View {
        VStack(alignment: .leading, spacing: Metrics.spacingSmall) {
            if relatedFindings.isEmpty == false {
                SectionLabel(title: "Findings")
                ForEach(relatedFindings) { finding in
                    FindingRow(finding: finding, context: .window)
                }
            }
            if relatedActivity.isEmpty == false {
                SectionLabel(title: "Recent activity")
                    .padding(.top, relatedFindings.isEmpty ? 0 : Metrics.spacingSmall)
                ForEach(relatedActivity) { event in
                    ActivityRow(event: event, context: .window)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
