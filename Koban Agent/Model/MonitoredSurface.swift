import Foundation

/// A software ecosystem Koban keeps an inventory of and watches for change.
enum MonitoredSurface: String, Codable, CaseIterable, Identifiable {
    case homebrew
    case claudeConfig
    case codexConfig
    case piConfig
    case cursorConfig
    case opencodeConfig
    case javascriptPackages
    case pythonPackages

    var id: String {
        rawValue
    }

    /// Human-facing name shown in the UI.
    var displayName: String {
        switch self {
        case .homebrew: "Homebrew"
        case .claudeConfig: "Claude"
        case .codexConfig: "Codex"
        case .piConfig: "Pi"
        case .cursorConfig: "Cursor"
        case .opencodeConfig: "OpenCode"
        case .javascriptPackages: "JavaScript"
        case .pythonPackages: "Python"
        }
    }

    /// A two-letter monogram shown in the UI's ecosystem chip. Brand marks differ per ecosystem
    /// and many have no usable dark-mode glyph, so a consistent monogram reads as designed rather
    /// than borrowing mismatched logos. Kept distinct across surfaces so no two collide.
    var monogram: String {
        switch self {
        case .homebrew: "Hb"
        case .claudeConfig: "Cl"
        case .codexConfig: "Cx"
        case .piConfig: "Pi"
        case .cursorConfig: "Cu"
        case .opencodeConfig: "Oc"
        case .javascriptPackages: "Js"
        case .pythonPackages: "Py"
        }
    }

    /// Whether a package's version is part of its identity on this surface. A lockfile-backed
    /// dependency tree legitimately holds the same package at several versions at once, so each
    /// (name, version) is a distinct artifact and a new version is an addition, not a change. On
    /// the other surfaces an item has a single mutable version, so a bump reads as a
    /// modification of the same item.
    var versionDefinesIdentity: Bool {
        switch self {
        case .javascriptPackages, .pythonPackages: true
        case .homebrew, .claudeConfig, .codexConfig, .piConfig, .cursorConfig, .opencodeConfig: false
        }
    }

    /// What a single inventory item on this surface represents, pluralised for counts.
    var itemNoun: String {
        switch self {
        case .homebrew: "package"
        case .claudeConfig, .codexConfig, .piConfig, .cursorConfig, .opencodeConfig: "config item"
        case .javascriptPackages, .pythonPackages: "package"
        }
    }
}
