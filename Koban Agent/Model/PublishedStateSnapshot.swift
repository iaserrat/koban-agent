// MARK: - PublishedStateSnapshot

struct PublishedStateSnapshot {
    let recentEvents: [ChangeEvent]
    let recentFindings: [Finding]
    let healthBySurface: [MonitoredSurface: SurfaceHealth]
    let itemCountsBySurface: [MonitoredSurface: Int]

    static let empty = Self(
        recentEvents: [],
        recentFindings: [],
        healthBySurface: [:],
        itemCountsBySurface: [:]
    )
}
