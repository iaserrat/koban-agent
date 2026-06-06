import Foundation
import OSLog
import Yams

/// Loads the agent configuration from `~/.config/koban/koban.yaml`. A missing file is normal
/// (we use the built-in defaults). A malformed file must never crash the agent: we log it
/// loudly and fall back to defaults - a deliberate, visible fallback, not a silent swallow.
enum ConfigurationLoader {
    static func load() -> KobanConfiguration {
        load(from: ConfigPaths.userConfigFile())
    }

    static func load(
        from url: URL,
        validator: ConfigurationFileValidator = ConfigurationFileValidator()
    ) -> KobanConfiguration {
        let data: Data
        do {
            try validator.validate(url)
            data = try Data(contentsOf: url)
        } catch CocoaError.fileReadNoSuchFile {
            Log.configuration.info("No user config at \(url.path, privacy: .public); using defaults.")
            return DefaultConfiguration.value
        } catch {
            let reason = String(describing: error)
            Log.configuration.error(
                "Unreadable config \(url.path, privacy: .public): \(reason, privacy: .public)."
            )
            return DefaultConfiguration.value
        }

        do {
            let configuration = try YAMLDecoder().decode(KobanConfiguration.self, from: data)
            Log.configuration.info("Loaded user config from \(url.path, privacy: .public).")
            return configuration
        } catch {
            let reason = String(describing: error)
            Log.configuration.error(
                "Invalid config \(url.path, privacy: .public): \(reason, privacy: .public). Using defaults."
            )
            return DefaultConfiguration.value
        }
    }
}
