import Foundation

// MARK: - HeuristicRule

/// A single configurable heuristic: when an item on `surface` satisfies `match` under one of
/// `triggers`, the engine raises a `Finding` of `severity`. Rules are data - the built-in set is
/// just the default configuration (see CLAUDE.md).
struct HeuristicRule: Hashable, Identifiable {
    var id: String
    var surface: MonitoredSurface
    var enabled: Bool
    var triggers: [RuleTrigger]
    var match: RuleMatch
    var severity: Severity
    var title: String
    var rationale: String
}

// MARK: Decodable

extension HeuristicRule: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id, surface, enabled, triggers, match, severity, title, rationale
        case field, values, allowed, schemes, flag, expected
    }

    /// The `match:` discriminator in YAML.
    private enum MatchKind: String, Decodable {
        case always, fieldContainsAny, fieldNotInList, fieldHasURLScheme, flagEquals
    }

    private static let defaultTriggers: [RuleTrigger] = [.added, .modified]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        surface = try container.decode(MonitoredSurface.self, forKey: .surface)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        triggers = try container.decodeIfPresent(
            [RuleTrigger].self,
            forKey: .triggers
        ) ?? Self.defaultTriggers
        severity = try container.decode(Severity.self, forKey: .severity)
        title = try container.decode(String.self, forKey: .title)
        rationale = try container.decode(String.self, forKey: .rationale)
        match = try Self.decodeMatch(from: container)
    }

    private static func decodeMatch(from container: KeyedDecodingContainer<CodingKeys>) throws -> RuleMatch {
        switch try container.decode(MatchKind.self, forKey: .match) {
        case .always:
            .always
        case .fieldContainsAny:
            try .fieldContainsAny(
                field: container.decode(RuleField.self, forKey: .field),
                values: container.decode([String].self, forKey: .values)
            )
        case .fieldNotInList:
            try .fieldNotInList(
                field: container.decode(RuleField.self, forKey: .field),
                allowed: container.decode([String].self, forKey: .allowed)
            )
        case .fieldHasURLScheme:
            try .fieldHasURLScheme(
                field: container.decode(RuleField.self, forKey: .field),
                schemes: container.decode([String].self, forKey: .schemes)
            )
        case .flagEquals:
            try .flagEquals(
                flag: container.decode(RuleFlag.self, forKey: .flag),
                expected: container.decode(Bool.self, forKey: .expected)
            )
        }
    }
}

// MARK: Encodable

extension HeuristicRule: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(surface, forKey: .surface)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(triggers, forKey: .triggers)
        try container.encode(severity, forKey: .severity)
        try container.encode(title, forKey: .title)
        try container.encode(rationale, forKey: .rationale)
        try Self.encodeMatch(match, into: &container)
    }

    /// Mirrors `decodeMatch`: writes the `match:` discriminator and only the parameters that case
    /// carries, so the closed DSL round-trips exactly.
    private static func encodeMatch(
        _ match: RuleMatch,
        into container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
        switch match {
        case .always:
            try container.encode(MatchKind.always.rawValue, forKey: .match)
        case let .fieldContainsAny(field, values):
            try container.encode(MatchKind.fieldContainsAny.rawValue, forKey: .match)
            try container.encode(field, forKey: .field)
            try container.encode(values, forKey: .values)
        case let .fieldNotInList(field, allowed):
            try container.encode(MatchKind.fieldNotInList.rawValue, forKey: .match)
            try container.encode(field, forKey: .field)
            try container.encode(allowed, forKey: .allowed)
        case let .fieldHasURLScheme(field, schemes):
            try container.encode(MatchKind.fieldHasURLScheme.rawValue, forKey: .match)
            try container.encode(field, forKey: .field)
            try container.encode(schemes, forKey: .schemes)
        case let .flagEquals(flag, expected):
            try container.encode(MatchKind.flagEquals.rawValue, forKey: .match)
            try container.encode(flag, forKey: .flag)
            try container.encode(expected, forKey: .expected)
        }
    }
}
