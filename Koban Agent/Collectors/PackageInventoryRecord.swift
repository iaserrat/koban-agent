import Foundation

/// Normalized package metadata before it becomes inventory.
struct PackageInventoryRecord: Hashable {
    var name: String
    var version: String?
    var manager: String
    var detail: String?
    var path: String
    var kind: InventoryKind

    init(
        name: String,
        version: String?,
        manager: String,
        detail: String?,
        path: String,
        kind: InventoryKind = .package
    ) {
        self.name = name
        self.version = version
        self.manager = manager
        self.detail = detail
        self.path = path
        self.kind = kind
    }
}
