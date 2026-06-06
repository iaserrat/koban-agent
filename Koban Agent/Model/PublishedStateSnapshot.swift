// MARK: - PublishedStateSnapshot

struct PublishedStateSnapshot {
    let recentEvents: [ChangeEvent]
    let recentFindings: [Finding]
    let healthBySurface: [MonitoredSurface: SurfaceHealth]
    let itemCountsBySurface: [MonitoredSurface: Int]
    /// The sensor's upload state, read in the same snapshot so the home dashboard's sync glance
    /// stays in step with the rest of the published view. Defaults to off when sync is unconfigured.
    var syncStatus: SyncStatus = .disabled

    static let empty = Self(
        recentEvents: [],
        recentFindings: [],
        healthBySurface: [:],
        itemCountsBySurface: [:]
    )
}
