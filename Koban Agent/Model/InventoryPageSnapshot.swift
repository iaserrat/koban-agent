struct InventoryPageSnapshot {
    let items: [InventoryItem]
    let totalCount: Int
    let nextCursor: InventoryPageCursor?

    init(items: [InventoryItem], totalCount: Int) {
        self.items = items
        self.totalCount = totalCount
        nextCursor = items.last.map(InventoryPageCursor.init(item:))
    }

    static let empty = Self(items: [], totalCount: 0)
}
