import SwiftUI

/// The heuristic ruleset editor: a list of rules with inline enable/severity, add and delete, and
/// a sheet for editing a rule's full definition (including its `match` predicate).
struct RulesSettingsSection: View {
    @Binding var rules: [HeuristicRule]
    @State private var editing: EditingRule?

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsRowSpacing) {
            HStack {
                SectionLabel(title: "Rules")
                Spacer()
                Button(action: addRule) {
                    Label("Add rule", systemImage: Symbols.addRule)
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.accent)
            }
            ForEach(rules.indices, id: \.self) { index in
                RuleSettingsRow(
                    rule: $rules[index],
                    onEdit: { editing = EditingRule(index: index) },
                    onDelete: { rules.remove(at: index) }
                )
            }
        }
        .sheet(item: $editing) { item in
            RuleEditorView(rule: $rules[item.index], onClose: { editing = nil })
        }
    }

    private func addRule() {
        rules.append(
            HeuristicRule(
                id: "new.rule",
                surface: .homebrew,
                enabled: true,
                triggers: [.added, .modified],
                match: .always,
                severity: .info,
                title: "New rule",
                rationale: ""
            )
        )
        editing = EditingRule(index: rules.count - 1)
    }
}
