enum SurfaceHealthState: String, Codable, Hashable, Comparable {
    case idle
    case healthy
    case stale
    case degraded

    static func < (lhs: Self, rhs: Self) -> Bool {
        guard
            let lhsIndex = orderedCases.firstIndex(of: lhs),
            let rhsIndex = orderedCases.firstIndex(of: rhs)
        else {
            return false
        }
        return lhsIndex < rhsIndex
    }

    private static let orderedCases: [Self] = [.idle, .healthy, .stale, .degraded]
}
