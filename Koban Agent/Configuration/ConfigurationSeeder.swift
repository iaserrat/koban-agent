import Foundation
import OSLog

/// Writes the bundled default configuration to `~/.config/koban/koban.yaml` on first launch so
/// users have a real, fully commented file to edit. It never overwrites an existing file:
/// `.withoutOverwriting` plus the existence guard make it safe even if two launches race.
enum ConfigurationSeeder {
    static func seedIfNeeded() {
        let destination = ConfigPaths.userConfigFile()
        let source = Bundle.main.url(
            forResource: ConfigPaths.bundledDefaultResource,
            withExtension: ConfigPaths.bundledDefaultExtension
        )

        do {
            let seeded = try seedIfNeeded(destination: destination, source: source)
            if seeded {
                Log.configuration.info("Seeded default config at \(destination.path, privacy: .public).")
            }
        } catch CocoaError.fileReadNoSuchFile {
            Log.configuration.error("Bundled default config not found; skipping seed.")
        } catch {
            Log.configuration.error("Could not seed config: \(error). Using built-in defaults.")
        }
    }

    @discardableResult
    static func seedIfNeeded(destination: URL, source: URL?) throws -> Bool {
        guard FileManager.default.fileExists(atPath: destination.path) == false else { return false }
        guard let source else { throw CocoaError(.fileReadNoSuchFile) }

        let contents = try Data(contentsOf: source)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        do {
            try contents.write(to: destination, options: .withoutOverwriting)
            return true
        } catch CocoaError.fileWriteFileExists {
            return false
        }
    }
}
