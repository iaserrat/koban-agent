import Foundation

// MARK: - RuleMatchKind

/// The discriminator for `RuleMatch`, surfaced for the rule editor's picker. Mirrors the closed
/// `match:` vocabulary (see CLAUDE.md) so the UI can only ever build a valid match. Kept apart
/// from `HeuristicRule`'s private decoding `MatchKind` because this one drives the UI.
enum RuleMatchKind: String, CaseIterable, Identifiable {
    case always
    case fieldContainsAny
    case fieldNotInList
    case fieldHasURLScheme
    case flagEquals

    var id: String {
        rawValue
    }

    /// A short human-facing label for the picker.
    var label: String {
        switch self {
        case .always: "Always"
        case .fieldContainsAny: "Field contains any"
        case .fieldNotInList: "Field not in list"
        case .fieldHasURLScheme: "Field has URL scheme"
        case .flagEquals: "Flag equals"
        }
    }

    init(_ match: RuleMatch) {
        switch match {
        case .always: self = .always
        case .fieldContainsAny: self = .fieldContainsAny
        case .fieldNotInList: self = .fieldNotInList
        case .fieldHasURLScheme: self = .fieldHasURLScheme
        case .flagEquals: self = .flagEquals
        }
    }

    /// Builds a match of this kind, carrying over the field and string list from `previous` so a
    /// user switching between the field-based kinds keeps their work instead of starting over.
    func match(preserving previous: RuleMatch) -> RuleMatch {
        let field = previous.editorField ?? .name
        let strings = previous.editorStrings
        switch self {
        case .always:
            return .always
        case .fieldContainsAny:
            return .fieldContainsAny(field: field, values: strings)
        case .fieldNotInList:
            return .fieldNotInList(field: field, allowed: strings)
        case .fieldHasURLScheme:
            return .fieldHasURLScheme(field: field, schemes: strings)
        case .flagEquals:
            return .flagEquals(
                flag: previous.editorFlag ?? .installedOnRequest,
                expected: previous.editorExpected ?? true
            )
        }
    }
}

// MARK: - RuleMatch editor accessors

extension RuleMatch {
    /// The field a field-based match keys on, or `nil` for `.always`/`.flagEquals`.
    var editorField: RuleField? {
        switch self {
        case let .fieldContainsAny(field, _),
             let .fieldNotInList(field, _),
             let .fieldHasURLScheme(field, _):
            field
        case .always, .flagEquals:
            nil
        }
    }

    /// The string list a field-based match carries (values/allowed/schemes), or `[]` otherwise.
    var editorStrings: [String] {
        switch self {
        case let .fieldContainsAny(_, values): values
        case let .fieldNotInList(_, allowed): allowed
        case let .fieldHasURLScheme(_, schemes): schemes
        case .always, .flagEquals: []
        }
    }

    var editorFlag: RuleFlag? {
        if case let .flagEquals(flag, _) = self { flag } else { nil }
    }

    var editorExpected: Bool? {
        if case let .flagEquals(_, expected) = self { expected } else { nil }
    }
}
