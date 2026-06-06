import Foundation

/// Where Koban looks for user configuration. The single home for config-path literals.
enum ConfigPaths {
    /// Directory under the home folder, e.g. `~/.config/koban`.
    static let directoryComponents = [".config", "koban"]
    static let fileName = "koban.yaml"

    /// The bundled default config copied to `userConfigFile()` on first launch.
    static let bundledDefaultResource = "koban.default"
    static let bundledDefaultExtension = "yaml"

    /// The user configuration file URL: `~/.config/koban/koban.yaml`.
    static func userConfigFile() -> URL {
        var url = KnownPaths.homeDirectory()
        for component in directoryComponents {
            url.append(component: component, directoryHint: .isDirectory)
        }
        return url.appending(component: fileName)
    }
}
