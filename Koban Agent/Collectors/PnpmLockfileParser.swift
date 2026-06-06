import Foundation
import Yams

/// Parses package keys from `pnpm-lock.yaml`.
struct PnpmLockfileParser {
    func records(from url: URL) throws -> [PackageInventoryRecord] {
        try Task.checkCancellation()
        let yaml = try String(contentsOf: url, encoding: .utf8)
        try Task.checkCancellation()
        guard let object = try Yams.load(yaml: yaml) as? [String: Any],
              let packages = object[PackageMetadataNames.npmPackagesKey] as? [String: Any]
        else { return [] }

        var records: [PackageInventoryRecord] = []
        for key in packages.keys {
            try Task.checkCancellation()
            guard let parsed = parsePackageKey(key) else { continue }
            records.append(
                PackageInventoryRecord(
                    name: parsed.name,
                    version: parsed.version,
                    manager: PackageMetadataNames.pnpmManager,
                    detail: nil,
                    path: url.path
                )
            )
        }
        return records
    }

    private func parsePackageKey(_ key: String) -> (name: String, version: String)? {
        let trimmed = key.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let separator = trimmed.lastIndex(of: Character(PackageMetadataNames.pnpmVersionSeparator))
        else { return nil }
        let name = String(trimmed[..<separator])
        let versionStart = trimmed.index(after: separator)
        let version = String(trimmed[versionStart...])
        guard name.isEmpty == false, version.isEmpty == false else { return nil }
        return (name, version)
    }
}
