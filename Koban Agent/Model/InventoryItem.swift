import Foundation

/// A single thing Koban knows is installed on a surface: a Homebrew package or an
/// MCP server. Snapshots are compared by `identity`; `version` and `provenance`
/// participate in equality so a version bump or re-pointed command reads as a change.
struct InventoryItem: Codable, Hashable, Identifiable {
    /// The surface this item belongs to.
    var surface: MonitoredSurface

    /// The item's category within its surface.
    var kind: InventoryKind

    /// The item's name within its surface and kind.
    var name: String

    /// Installed version, when the surface exposes one (`nil` for MCP servers).
    var version: String?

    /// Absolute path the item was discovered at.
    var path: String

    /// Reconstructed origin information.
    var provenance: Provenance

    /// Stable identity across snapshots: a given name at a given discovery path is one item.
    /// Version is part of that identity only on surfaces where several versions of one package
    /// coexist (see `MonitoredSurface.versionDefinesIdentity`); elsewhere a version bump is a
    /// modification of the same item. The path keeps `/opt/homebrew` and `/usr/local` distinct.
    init(
        surface: MonitoredSurface,
        kind: InventoryKind = .package,
        name: String,
        version: String? = nil,
        path: String,
        provenance: Provenance
    ) {
        self.surface = surface
        self.kind = kind
        self.name = name
        self.version = version
        self.path = path
        self.provenance = provenance
    }

    var id: String {
        let base = "\(surface.rawValue)/\(kind.rawValue)/\(path)/\(name)"
        guard surface.versionDefinesIdentity else { return base }
        return "\(base)/\(version ?? "")"
    }
}
