import Foundation

// MARK: - NpmLockfileParser

/// Parses npm `package-lock.json` and `npm-shrinkwrap.json` files.
struct NpmLockfileParser {
    func records(from url: URL, manager: String) throws -> [PackageInventoryRecord] {
        try Task.checkCancellation()
        let data = try Data(contentsOf: url)
        try Task.checkCancellation()
        let file = try JSONDecoder().decode(NpmLockfile.self, from: data)
        try Task.checkCancellation()
        var records: [PackageInventoryRecord] = []
        for (path, package) in file.packages ?? [:] {
            try Task.checkCancellation()
            guard path.isEmpty == false,
                  path.hasPrefix(PackageMetadataNames.packagePathPrefix),
                  let version = package.version
            else { continue }
            let name = String(path.dropFirst(PackageMetadataNames.packagePathPrefix.count))
            records.append(
                PackageInventoryRecord(
                    name: name,
                    version: version,
                    manager: manager,
                    detail: package.detail,
                    path: url.path
                )
            )
        }
        return records
    }
}

extension NpmPackage {
    fileprivate var detail: String? {
        var parts: [String] = []
        if let resolved {
            parts.append("\(PackageMetadataNames.resolvedDetailKey)=\(resolved)")
        }
        if let integrity {
            parts.append("\(PackageMetadataNames.integrityDetailKey)=\(integrity)")
        }
        if let scope {
            parts.append("\(PackageMetadataNames.scopeDetailKey)=\(scope)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: PackageMetadataNames.detailSeparator)
    }

    private var scope: String? {
        if dev == true {
            return PackageMetadataNames.devScope
        }
        if optional == true {
            return PackageMetadataNames.optionalScope
        }
        return nil
    }
}
