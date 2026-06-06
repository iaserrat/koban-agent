import Foundation

/// The nature of a detected change to an inventory item.
enum ChangeKind: String, Codable, CaseIterable, Identifiable {
    case added
    case removed
    case modified

    var id: String {
        rawValue
    }

    /// SF Symbol shown next to the change in the activity feed.
    var systemImageName: String {
        switch self {
        case .added: "plus"
        case .removed: "minus"
        case .modified: "pencil"
        }
    }

    /// Human-facing label for the change, shown in the monitor's Event column.
    var displayName: String {
        switch self {
        case .added: "Added"
        case .removed: "Removed"
        case .modified: "Modified"
        }
    }
}
