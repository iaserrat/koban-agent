// MARK: - WindowSnapshot

struct WindowSnapshot {
    let findings: [Finding]
    let activity: [ChangeEvent]
    let inventories: [MonitoredSurface: [InventoryItem]]
    let inventoryCountsBySurface: [MonitoredSurface: Int]

    static let empty = Self(
        findings: [],
        activity: [],
        inventories: [:],
        inventoryCountsBySurface: [:]
    )
}
