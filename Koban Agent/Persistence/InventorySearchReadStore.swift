import GRDB

struct InventorySearchReadStore {
    func items(
        matching pageRequest: InventoryPageRequest,
        query: String,
        in db: Database
    ) throws -> [InventoryItem] {
        var sql = ReadModelQueries.inventorySearchPage
        var arguments: StatementArguments = [query, pageRequest.surface.rawValue]
        if let cursor = pageRequest.cursor {
            sql += ReadModelQueries.inventorySearchPageAfterCursor
            arguments += cursor.searchArguments
        }
        sql += ReadModelQueries.inventorySearchPageOrder
        arguments += [pageRequest.limit]
        return try InventoryItem.fetchAll(db, sql: sql, arguments: arguments)
    }

    func count(
        matching query: String,
        surface: MonitoredSurface,
        in db: Database
    ) throws -> Int {
        try Int.fetchOne(
            db,
            sql: ReadModelQueries.inventorySearchCount,
            arguments: [query, surface.rawValue]
        ) ?? 0
    }
}
