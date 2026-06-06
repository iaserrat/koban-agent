import Foundation

/// When a heuristic rule should evaluate. Change triggers run only against inventory diffs;
/// `present` runs against the current snapshot and is deduped by item and rule.
enum RuleTrigger: String, Codable, CaseIterable, Identifiable {
    case added
    case removed
    case modified
    case present

    init(_ changeKind: ChangeKind) {
        switch changeKind {
        case .added: self = .added
        case .removed: self = .removed
        case .modified: self = .modified
        }
    }

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .added: "Added"
        case .removed: "Removed"
        case .modified: "Modified"
        case .present: "Present"
        }
    }
}
