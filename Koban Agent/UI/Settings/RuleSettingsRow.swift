import SwiftUI

/// One rule in the rules list: an enable switch, its title and identity, its severity, and a
/// delete button. Tapping the row opens the editor.
struct RuleSettingsRow: View {
    @Binding var rule: HeuristicRule
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: Metrics.spacingMedium) {
            Toggle("", isOn: $rule.enabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Palette.accent)
            VStack(alignment: .leading, spacing: Metrics.spacingTight) {
                Text(rule.title)
                    .font(.callout)
                    .foregroundStyle(Palette.ink)
                Text("\(rule.surface.displayName) · \(rule.id)")
                    .font(.caption)
                    .foregroundStyle(Palette.inkSubtle)
            }
            Spacer()
            SeverityBadge(severity: rule.severity)
            Button(action: onDelete) {
                Image(systemName: Symbols.deleteRule)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.inkSubtle)
        }
        .padding(Metrics.settingsRulePadding)
        .background(
            RoundedRectangle(cornerRadius: Metrics.rowCornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.rowCornerRadius, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}
