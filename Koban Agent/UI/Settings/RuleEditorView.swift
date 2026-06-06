import SwiftUI

/// Edits one heuristic rule, presented as a sheet. Binds straight to the rule in the draft, so
/// edits apply live; Done just closes. Triggers are a set rendered as toggles; the predicate is
/// edited by `RuleMatchEditor`.
struct RuleEditorView: View {
    @Binding var rule: HeuristicRule
    let onClose: () -> Void

    private let rationaleLines = Metrics.settingsRationaleMinLines ... Metrics.settingsRationaleMaxLines

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Palette.border)
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.settingsRowSpacing) {
                    SettingsRow(label: "ID") {
                        TextField("", text: $rule.id)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(Palette.ink)
                    }
                    SettingsRow(label: "Surface") {
                        Picker("", selection: $rule.surface) {
                            ForEach(MonitoredSurface.allCases) { Text($0.displayName).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(Palette.ink)
                    }
                    SettingsRow(label: "Severity") {
                        Picker("", selection: $rule.severity) {
                            ForEach(Severity.allCases, id: \.self) { Text($0.label).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .tint(Palette.ink)
                    }
                    SettingsRow(label: "Title") {
                        TextField("", text: $rule.title)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(Palette.ink)
                    }
                    SettingsRow(label: "Rationale") {
                        TextField("", text: $rule.rationale, axis: .vertical)
                            .lineLimit(rationaleLines)
                            .textFieldStyle(.roundedBorder)
                            .foregroundStyle(Palette.ink)
                    }
                    triggersRow
                    SettingsToggleRow(label: "Enabled", isOn: $rule.enabled)
                    Divider().overlay(Palette.border)
                    RuleMatchEditor(match: $rule.match)
                }
                .padding(Metrics.settingsContentPadding)
            }
        }
        .frame(width: Metrics.settingsSheetWidth, height: Metrics.settingsSheetHeight)
        .background(Palette.bg)
    }

    private var header: some View {
        HStack {
            Text("Edit rule")
                .font(.headline)
                .foregroundStyle(Palette.ink)
            Spacer()
            Button("Done", action: onClose)
                .buttonStyle(.borderedProminent)
                .tint(Palette.accent)
        }
        .padding(Metrics.settingsContentPadding)
    }

    private var triggersRow: some View {
        SettingsRow(label: "Triggers") {
            HStack(spacing: Metrics.spacingSmall) {
                ForEach(ChangeKind.allCases) { kind in
                    Toggle(kind.displayName, isOn: triggerBinding(kind))
                        .toggleStyle(.button)
                        .tint(Palette.accent)
                }
            }
        }
    }

    private func triggerBinding(_ kind: ChangeKind) -> Binding<Bool> {
        Binding(
            get: { rule.triggers.contains(kind) },
            set: { isOn in
                var selected = Set(rule.triggers)
                if isOn { selected.insert(kind) } else { selected.remove(kind) }
                rule.triggers = ChangeKind.allCases.filter { selected.contains($0) }
            }
        )
    }
}
