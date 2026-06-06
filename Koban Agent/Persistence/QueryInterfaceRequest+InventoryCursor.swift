import GRDB

extension QueryInterfaceRequest where RowDecoder == InventoryItem {
    func filter(cursor: InventoryPageCursor?) -> Self {
        guard let cursor else { return self }
        return filter(
            sql: ReadModelQueries.inventoryPageAfterCursor,
            arguments: [
                cursor.name,
                cursor.name,
                cursor.path,
                cursor.name,
                cursor.path,
                cursor.kind.rawValue
            ]
        )
    }
}
