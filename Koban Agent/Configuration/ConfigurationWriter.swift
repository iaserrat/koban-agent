import Foundation
import Yams

/// Serialises the configuration back to `~/.config/koban/koban.yaml`. The UI edits a full model
/// and we regenerate the file from it, so hand-written comments and key ordering are not
/// preserved (the commented template lives in the bundle, `koban.default.yaml`). `encode` is a
/// pure string transform; only `write` touches the filesystem (IO at the edge, see CLAUDE.md).
enum ConfigurationWriter {
    static func encode(_ configuration: KobanConfiguration) throws -> String {
        try YAMLEncoder().encode(configuration)
    }

    static func write(
        _ configuration: KobanConfiguration,
        to url: URL = ConfigPaths.userConfigFile()
    ) throws {
        let yaml = try encode(configuration)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(yaml.utf8).write(to: url, options: .atomic)
    }
}
