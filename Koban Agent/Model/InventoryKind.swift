import Foundation

/// Closed inventory categories shared across monitored surfaces.
enum InventoryKind: String, Codable, Hashable, CaseIterable {
    case package
    case mcpServer
    case hook
    case skill
    case agent
    case command
    case instruction
    case plugin
    case rule
    case settings
    case configProfile
    case `import`
    case pythonDeclaredRequirement
    case pythonResolvedPackage
    case pythonConstraint
}
