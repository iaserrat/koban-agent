import Foundation

/// Homebrew collection settings.
struct HomebrewSettings: Codable, Hashable {
    var enabled: Bool
    var prefixes: [String]?

    init(enabled: Bool, prefixes: [String]?) {
        self.enabled = enabled
        self.prefixes = prefixes
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = DefaultConfiguration.value.homebrew
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? defaults.enabled
        prefixes = try container.decodeIfPresent([String].self, forKey: .prefixes) ?? defaults.prefixes
    }

    private enum CodingKeys: String, CodingKey {
        case enabled
        case prefixes
    }
}
