import Foundation

// MARK: - RuleField

/// The inspectable string fields of an inventory item. Closed set: rules may only look at
/// these, which keeps the engine bounded and the YAML vocabulary fixed (see CLAUDE.md).
enum RuleField: String, Codable, CaseIterable, Identifiable {
    var id: String {
        rawValue
    }

    case kind
    case name
    case version
    case origin
    case detail
    case path
    case packageManager
    case registry
    case sourceURL
    case command
    case dependencyScope
    case fileHash

    /// Extracts the field's value from an item, or `nil` when absent.
    func value(in item: InventoryItem) -> String? {
        let directValues: [Self: String?] = [
            .kind: item.kind.rawValue,
            .name: item.name,
            .version: item.version,
            .origin: item.provenance.origin,
            .detail: item.provenance.detail,
            .path: item.path
        ]
        if let value = directValues[self] {
            return value
        }
        switch self {
        case .packageManager:
            return packageManager(in: item)
        case .registry:
            return registry(in: item)
        case .sourceURL:
            return detailValue(PackageMetadataNames.resolvedDetailKey, in: item)
        case .command:
            return command(in: item)
        case .dependencyScope:
            return detailValue(PackageMetadataNames.scopeDetailKey, in: item)
        case .fileHash:
            return fileHash(in: item)
        case .kind, .name, .version, .origin, .detail, .path:
            return nil
        }
    }

    private func packageManager(in item: InventoryItem) -> String? {
        switch item.surface {
        case .javascriptPackages, .pythonPackages: item.provenance.origin
        default: nil
        }
    }

    private func registry(in item: InventoryItem) -> String? {
        guard let sourceURL = detailValue(PackageMetadataNames.resolvedDetailKey, in: item),
              let host = URL(string: sourceURL)?.host()
        else { return nil }
        return host
    }

    private func command(in item: InventoryItem) -> String? {
        guard item.kind == .mcpServer else { return nil }
        let origin = item.provenance.origin
        guard URL(string: origin)?.scheme == nil else { return nil }
        return origin
    }

    private func fileHash(in item: InventoryItem) -> String? {
        guard let detail = item.provenance.detail else { return nil }
        let isFileHash = detail.count == FileHashNames.digestLength
            && detail.allSatisfy { FileHashNames.hexDigits.contains($0) }
        if isFileHash {
            return detail
        }
        return detailValue(FileHashNames.detailKey, in: item)
    }

    private func detailValue(_ key: String, in item: InventoryItem) -> String? {
        item.provenance.detail?
            .split(separator: Character(PackageMetadataNames.detailSeparator))
            .compactMap { part -> String? in
                let prefix = key + "="
                guard part.hasPrefix(prefix) else { return nil }
                return String(part.dropFirst(prefix.count))
            }
            .first
    }
}
