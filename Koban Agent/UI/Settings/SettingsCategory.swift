import Foundation

/// The Settings page's left-hand navigation: which configuration section the content pane shows.
enum SettingsCategory: String, CaseIterable, Identifiable {
    case watch
    case retention
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

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .watch: "Watch"
        case .retention: "Retention"
        case .sync: "Sync"
        case .homebrew: "Homebrew"
        case .claude: "Claude"
        case .codex: "Codex"
        case .pi: "Pi"
        case .cursor: "Cursor"
        case .opencode: "OpenCode"
        case .javascript: "JavaScript"
        case .python: "Python"
        case .rules: "Rules"
        }
    }

    /// One-line description shown under the title in the content header, so a section always reads
    /// as finished rather than opening to an unlabelled form.
    var summary: String {
        switch self {
        case .watch: "Pipeline timing and project discovery"
        case .retention: "How long activity and history are kept"
        case .sync: "Fleet enrollment and reporting"
        case .homebrew: "Watched Homebrew formulae and casks"
        case .claude: "Watched Claude configuration"
        case .codex: "Watched Codex configuration"
        case .pi: "Watched Pi configuration"
        case .cursor: "Watched Cursor configuration"
        case .opencode: "Watched OpenCode configuration"
        case .javascript: "Watched JavaScript packages"
        case .python: "Watched Python packages"
        case .rules: "Indicator-of-compromise heuristics"
        }
    }

    /// Which sidebar block this category sits under.
    var group: SettingsCategoryGroup {
        switch self {
        case .watch, .retention, .sync: .pipeline
        case .homebrew, .claude, .codex, .pi, .cursor, .opencode, .javascript, .python: .ecosystems
        case .rules: .rules
        }
    }

    /// The leading glyph the sidebar row draws: an ecosystem's monogram chip, or an SF Symbol for
    /// the pipeline sections and the ruleset.
    var icon: SettingsCategoryIcon {
        switch self {
        case .watch: .symbol(Symbols.settingsWatch)
        case .retention: .symbol(Symbols.settingsRetention)
        case .sync: .symbol(Symbols.settingsSync)
        case .homebrew: .surface(.homebrew)
        case .claude: .surface(.claudeConfig)
        case .codex: .surface(.codexConfig)
        case .pi: .surface(.piConfig)
        case .cursor: .surface(.cursorConfig)
        case .opencode: .surface(.opencodeConfig)
        case .javascript: .surface(.javascriptPackages)
        case .python: .surface(.pythonPackages)
        case .rules: .symbol(Symbols.settingsRules)
        }
    }
}
