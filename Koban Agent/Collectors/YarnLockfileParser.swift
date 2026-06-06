import Foundation

/// Bounded parser for Yarn lockfile package selectors and versions.
struct YarnLockfileParser {
    func records(from url: URL) throws -> [PackageInventoryRecord] {
        try Task.checkCancellation()
        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n", omittingEmptySubsequences: false)
        try Task.checkCancellation()
        var records: [PackageInventoryRecord] = []
        var currentName: String?

        for line in lines {
            try Task.checkCancellation()
            let text = String(line)
            if text.hasPrefix(" ") == false, text.hasSuffix(":") {
                currentName = packageName(from: String(text.dropLast()))
                continue
            }
            if let name = currentName, let version = version(from: text) {
                records.append(
                    PackageInventoryRecord(
                        name: name,
                        version: version,
                        manager: PackageMetadataNames.yarnManager,
                        detail: nil,
                        path: url.path
                    )
                )
                currentName = nil
            }
        }

        return records
    }

    private func packageName(from selectorLine: String) -> String? {
        let selectors = selectorLine
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .split(separator: ",")
        guard let first = selectors.first else { return nil }
        let selector = first.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = selector.range(of: PackageMetadataNames.yarnNPMProtocol) {
            return String(selector[..<range.lowerBound])
        }
        guard let separator = selector.lastIndex(of: Character(PackageMetadataNames.pnpmVersionSeparator))
        else { return String(selector) }
        return String(selector[..<separator])
    }

    private func version(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix(PackageMetadataNames.yarnVersionPrefix) else { return nil }
        return trimmed
            .dropFirst(PackageMetadataNames.yarnVersionPrefix.count)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}
