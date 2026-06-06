import Foundation

// MARK: - KobanConfiguration

/// The whole agent configuration: what to watch, how often, and the ruleset to evaluate.
/// Decoded from `~/.config/koban/koban.yaml`; any section the user omits falls back to the
/// built-in `DefaultConfiguration`, so a partial file is always valid (section-level merge).
struct KobanConfiguration: Hashable {
    var watch: WatchSettings
    var persistence: PersistenceSettings
    var sync: SyncSettings
    var homebrew: HomebrewSettings
    var claude: ClaudeSettings
    var codex: CodexSettings
    var pi: PiSettings
    var cursor: CursorSettings
    var opencode: OpenCodeSettings
    var javascript: JavaScriptPackageSettings
    var python: PythonPackageSettings
    var rules: [HeuristicRule]
}

// MARK: Decodable

extension KobanConfiguration: Decodable {
    private enum CodingKeys: String, CodingKey {
        case watch
        case persistence
        case sync
        case homebrew
        case claude
        case codex
        case pi
        case cursor
        case opencode
        case javascript
        case python
        case rules
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = DefaultConfiguration.value
        watch = try container.decodeIfPresent(WatchSettings.self, forKey: .watch) ?? base.watch
        persistence = try container.decodeIfPresent(
            PersistenceSettings.self,
            forKey: .persistence
        ) ?? base.persistence
        sync = try container.decodeIfPresent(SyncSettings.self, forKey: .sync) ?? base.sync
        homebrew = try container.decodeIfPresent(HomebrewSettings.self, forKey: .homebrew) ?? base.homebrew
        claude = try container.decodeIfPresent(ClaudeSettings.self, forKey: .claude) ?? base.claude
        codex = try container.decodeIfPresent(CodexSettings.self, forKey: .codex) ?? base.codex
        pi = try container.decodeIfPresent(PiSettings.self, forKey: .pi) ?? base.pi
        cursor = try container.decodeIfPresent(CursorSettings.self, forKey: .cursor) ?? base.cursor
        opencode = try container.decodeIfPresent(OpenCodeSettings.self, forKey: .opencode) ?? base.opencode
        javascript = try container.decodeIfPresent(
            JavaScriptPackageSettings.self,
            forKey: .javascript
        ) ?? base.javascript
        python = try container.decodeIfPresent(PythonPackageSettings.self, forKey: .python) ?? base.python
        rules = try container.decodeIfPresent([HeuristicRule].self, forKey: .rules) ?? base.rules
    }
}

// MARK: Encodable

extension KobanConfiguration: Encodable {
    /// Emits the whole configuration explicitly: the UI edits a complete model, so the written
    /// file is fully self-describing. (Decoding stays tolerant of partial files; encoding never is.)
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(watch, forKey: .watch)
        try container.encode(persistence, forKey: .persistence)
        try container.encode(sync, forKey: .sync)
        try container.encode(homebrew, forKey: .homebrew)
        try container.encode(claude, forKey: .claude)
        try container.encode(codex, forKey: .codex)
        try container.encode(pi, forKey: .pi)
        try container.encode(cursor, forKey: .cursor)
        try container.encode(opencode, forKey: .opencode)
        try container.encode(javascript, forKey: .javascript)
        try container.encode(python, forKey: .python)
        try container.encode(rules, forKey: .rules)
    }
}
