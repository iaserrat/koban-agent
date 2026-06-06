import Foundation

/// Renders the human-facing detail string for a modified inventory item.
enum VersionChange {
    private static let arrow = " → "
    private static let unknownVersion = "?"

    static func describe(from old: InventoryItem, to new: InventoryItem) -> String {
        if old.version != new.version {
            return (old.version ?? unknownVersion) + arrow + (new.version ?? unknownVersion)
        }
        if old.provenance.origin != new.provenance.origin {
            return old.provenance.origin + arrow + new.provenance.origin
        }
        return new.provenance.origin
    }
}
