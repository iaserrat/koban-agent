import SwiftUI

/// Edits a rule's `match` predicate. The kind picker drives which parameters show, and the
/// computed bindings read and write the associated values of the current `RuleMatch` case, so the
/// editor can only ever produce a valid match in the closed DSL (see CLAUDE.md).
struct RuleMatchEditor: View {
    @Binding var match: RuleMatch

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsRowSpacing) {
            SettingsRow(label: "Match") {
                Picker("", selection: kindBinding) {
                    ForEach(RuleMatchKind.allCases) { Text($0.label).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(Palette.ink)
            }

            switch match {
            case .always:
                EmptyView()
            case .fieldContainsAny:
                fieldPicker
                SettingsStringListEditor(label: "Values", items: stringsBinding)
            case .fieldNotInList:
                fieldPicker
                SettingsStringListEditor(label: "Allowed", items: stringsBinding)
            case .fieldHasURLScheme:
                fieldPicker
                SettingsStringListEditor(label: "Schemes", items: stringsBinding)
            case .flagEquals:
                flagPicker
                SettingsToggleRow(label: "Expected", isOn: expectedBinding)
            }
        }
    }

    private var fieldPicker: some View {
        SettingsRow(label: "Field") {
            Picker("", selection: fieldBinding) {
                ForEach(RuleField.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Palette.ink)
        }
    }

    private var flagPicker: some View {
        SettingsRow(label: "Flag") {
            Picker("", selection: flagBinding) {
                ForEach(RuleFlag.allCases) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(Palette.ink)
        }
    }

    private var kindBinding: Binding<RuleMatchKind> {
        Binding(
            get: { RuleMatchKind(match) },
            set: { match = $0.match(preserving: match) }
        )
    }

    private var fieldBinding: Binding<RuleField> {
        Binding(
            get: { match.editorField ?? .name },
            set: { newField in
                switch match {
                case let .fieldContainsAny(_, values):
                    match = .fieldContainsAny(field: newField, values: values)
                case let .fieldNotInList(_, allowed):
                    match = .fieldNotInList(field: newField, allowed: allowed)
                case let .fieldHasURLScheme(_, schemes):
                    match = .fieldHasURLScheme(field: newField, schemes: schemes)
                case .always, .flagEquals:
                    break
                }
            }
        )
    }

    private var stringsBinding: Binding<[String]> {
        Binding(
            get: { match.editorStrings },
            set: { newValues in
                switch match {
                case let .fieldContainsAny(field, _):
                    match = .fieldContainsAny(field: field, values: newValues)
                case let .fieldNotInList(field, _):
                    match = .fieldNotInList(field: field, allowed: newValues)
                case let .fieldHasURLScheme(field, _):
                    match = .fieldHasURLScheme(field: field, schemes: newValues)
                case .always, .flagEquals:
                    break
                }
            }
        )
    }

    private var flagBinding: Binding<RuleFlag> {
        Binding(
            get: { match.editorFlag ?? .installedOnRequest },
            set: { newFlag in
                if case let .flagEquals(_, expected) = match {
                    match = .flagEquals(flag: newFlag, expected: expected)
                }
            }
        )
    }

    private var expectedBinding: Binding<Bool> {
        Binding(
            get: { match.editorExpected ?? true },
            set: { newExpected in
                if case let .flagEquals(flag, _) = match {
                    match = .flagEquals(flag: flag, expected: newExpected)
                }
            }
        )
    }
}
