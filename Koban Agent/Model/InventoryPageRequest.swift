struct InventoryPageRequest: Hashable {
    let surface: MonitoredSurface
    let limit: Int
    let searchText: InventorySearchText
    let cursor: InventoryPageCursor?

    init(
        surface: MonitoredSurface,
        limit: Int,
        searchText: InventorySearchText = .empty,
        cursor: InventoryPageCursor? = nil
    ) {
        self.surface = surface
        self.limit = limit
        self.searchText = searchText
        self.cursor = cursor
    }
}
