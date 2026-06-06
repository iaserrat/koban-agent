import Foundation

// MARK: - RuleFlag

/// The inspectable boolean flags of an inventory item.
enum RuleFlag: String, Codable, CaseIterable, Identifiable {
    var id: String {
        rawValue
    }

    case hasInstallScript
    case installedOnRequest
    case isDirectDependency
    case isEditable
    case isExecutableConfig
    case isPromptShapingConfig
    case usesDynamicAuthHelper
    case usesEphemeralRunner
    case usesRemote

    /// Extracts the flag's value from an item, or `nil` when the surface has no such concept.
    func value(in item: InventoryItem) -> Bool? {
        if self == .installedOnRequest {
            return item.provenance.installedOnRequest
        }
        if self == .isDirectDependency {
            return RuleField.dependencyScope.value(in: item) == nil
        }
        if self == .isExecutableConfig {
            return [.hook, .command, .plugin, .mcpServer].contains(item.kind)
        }
        if self == .isPromptShapingConfig {
            return [.agent, .instruction, .rule, .settings, .skill].contains(item.kind)
        }
        if self == .usesDynamicAuthHelper {
            return item.provenance.detail?.contains(HeuristicConstants.dynamicAuthHelperToken)
        }
        guard let detail = item.provenance.detail else { return nil }
        if self == .usesEphemeralRunner {
            return HeuristicConstants.ephemeralRunnerCommands.contains { detail.contains($0) }
        }
        if self == .usesRemote {
            return HeuristicConstants.remoteTransportSchemes.contains { scheme in
                detail.hasPrefix(scheme + HeuristicConstants.urlSchemeSeparator)
            }
        }
        return nil
    }
}
