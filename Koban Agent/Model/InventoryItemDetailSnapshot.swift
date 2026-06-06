struct InventoryItemDetailSnapshot {
    let findings: [Finding]
    let activity: [ChangeEvent]

    static let empty = Self(findings: [], activity: [])
}
