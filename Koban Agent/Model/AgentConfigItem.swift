import Foundation

/// Normalized behavior-affecting agent configuration before it becomes inventory.
struct AgentConfigItem: Hashable {
    var surface: MonitoredSurface
    var kind: InventoryKind
    var name: String
    var version: String?
    var path: String
    var origin: String
    var detail: String?

    init(
        surface: MonitoredSurface,
        kind: InventoryKind,
        name: String,
        version: String? = nil,
        path: String,
        origin: String,
        detail: String? = nil
    ) {
        self.surface = surface
        self.kind = kind
        self.name = name
        self.version = version
        self.path = path
        self.origin = origin
        self.detail = detail
    }
}
