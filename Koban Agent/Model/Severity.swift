import Foundation

/// How much attention a change or finding deserves. Ordered from least to most urgent
/// so the menu-bar icon can reflect the worst open severity.
enum Severity: String, Codable, CaseIterable, Comparable {
    case info
    case notable
    case suspicious
    case critical

    /// Ordering follows declaration order, so `info < notable < suspicious < critical`.
    static func < (lhs: Self, rhs: Self) -> Bool {
        guard
            let lhsIndex = allCases.firstIndex(of: lhs),
            let rhsIndex = allCases.firstIndex(of: rhs)
        else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
