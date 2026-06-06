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
}
