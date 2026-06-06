import Foundation

/// The predicate a heuristic rule tests against a changed item. A closed set, encoded in
/// YAML with a `match:` discriminator and the parameters each case needs, e.g.:
///
/// ```yaml
/// match: fieldContainsAny
/// field: detail
/// values: [curl, wget, "| sh"]
/// ```
enum RuleMatch: Hashable {
    /// Always fires (gated only by the rule's `triggers`), e.g. "a server was added".
    case always

    /// The field's value contains any of the substrings (case-insensitive).
    case fieldContainsAny(field: RuleField, values: [String])

    /// The field's value is non-empty and not present in the allow-list.
    case fieldNotInList(field: RuleField, allowed: [String])

    /// The field's value parses as a URL whose scheme is one of `schemes`.
    case fieldHasURLScheme(field: RuleField, schemes: [String])

    /// The flag is present and equals `expected`.
    case flagEquals(flag: RuleFlag, expected: Bool)

    /// The field/flag this predicate keyed on and its value in `item`, recorded as evidence so
    /// the detail view can show exactly what tripped the rule. `nil` for `.always`, which keys
    /// on no field. The field name is a `RuleField`/`RuleFlag` raw value.
    func matchedField(in item: InventoryItem) -> (field: String, value: String?)? {
        switch self {
        case .always:
            nil
        case let .fieldContainsAny(field, _),
             let .fieldNotInList(field, _),
             let .fieldHasURLScheme(field, _):
            (field.rawValue, field.value(in: item))
        case let .flagEquals(flag, _):
            (flag.rawValue, flag.value(in: item).map(String.init))
        }
    }

    /// Evaluates the predicate against an item.
    func matches(_ item: InventoryItem) -> Bool {
        switch self {
        case .always:
            true
        case let .fieldContainsAny(field, values):
            Self.containsAny(field.value(in: item), values)
        case let .fieldNotInList(field, allowed):
            Self.notInList(field.value(in: item), allowed)
        case let .fieldHasURLScheme(field, schemes):
            Self.hasURLScheme(field.value(in: item), schemes)
        case let .flagEquals(flag, expected):
            flag.value(in: item) == expected
        }
    }

    private static func containsAny(_ value: String?, _ values: [String]) -> Bool {
        guard let value = value?.lowercased() else { return false }
        return values.contains { value.contains($0.lowercased()) }
    }

    private static func notInList(_ value: String?, _ allowed: [String]) -> Bool {
        guard let value, value.isEmpty == false else { return false }
        return allowed.contains(value) == false
    }

    private static func hasURLScheme(_ value: String?, _ schemes: [String]) -> Bool {
        guard let value, let scheme = URLComponents(string: value)?.scheme?.lowercased() else {
            return false
        }
        return schemes.map { $0.lowercased() }.contains(scheme)
    }
}
