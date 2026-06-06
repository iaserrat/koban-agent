import Foundation

/// A Claude directory whose files become agent-config inventory items.
struct ClaudeCustomizationDirectory: Hashable {
    var url: URL
    var kind: InventoryKind
}
