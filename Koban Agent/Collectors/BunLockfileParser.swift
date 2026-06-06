import Foundation

/// Parses package entries from Bun's text JSON lockfile.
struct BunLockfileParser {
    func records(from url: URL) throws -> [PackageInventoryRecord] {
        try Task.checkCancellation()
        let data = try Data(contentsOf: url)
        try Task.checkCancellation()
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let packages = object[PackageMetadataNames.npmPackagesKey] as? [String: Any]
        else { return [] }
        var records: [PackageInventoryRecord] = []
        for (name, value) in packages {
            try Task.checkCancellation()
            records.append(
                PackageInventoryRecord(
                    name: name,
                    version: version(from: value),
                    manager: PackageMetadataNames.bunManager,
                    detail: nil,
                    path: url.path
                )
            )
        }
        return records
    }

    private func version(from value: Any) -> String? {
        guard let array = value as? [Any], let identifier = array.first as? String else { return nil }
        guard let separator = identifier.lastIndex(of: Character(PackageMetadataNames.pnpmVersionSeparator))
        else { return nil }
        return String(identifier[identifier.index(after: separator)...])
    }
}
