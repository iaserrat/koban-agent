import GRDB

// MARK: - ReadModelStore

struct ReadModelStore {
    let database: AppDatabase
    private let inventorySearch = InventorySearchReadStore()

    func publishedState(eventLimit: Int, findingLimit: Int) throws -> PublishedStateSnapshot {
        try database.reader.read { db in
            let events = try ChangeEvent
                .order(Column(ReadModelQueries.timestamp).desc)
                .limit(eventLimit)
                .fetchAll(db)
            let findings = try Finding
                .order(Column(ReadModelQueries.timestamp).desc)
                .limit(findingLimit)
                .fetchAll(db)
            let health = try SurfaceHealth
                .order(Column(ReadModelQueries.surface))
                .fetchAll(db)
            let counts = try itemCounts(in: db)
            return PublishedStateSnapshot(
                recentEvents: events,
                recentFindings: findings,
                healthBySurface: Dictionary(uniqueKeysWithValues: health.map { ($0.surface, $0) }),
                itemCountsBySurface: counts
            )
        }
    }

    func windowSnapshot(
        activityLimit: Int,
        findingLimit: Int,
        inventoryLimitPerSurface: Int
    ) throws -> WindowSnapshot {
        try database.reader.read { db in
            let findings = try Finding
                .order(Column(ReadModelQueries.timestamp).desc)
                .limit(findingLimit)
                .fetchAll(db)
            let activity = try ChangeEvent
                .order(Column(ReadModelQueries.timestamp).desc)
                .limit(activityLimit)
                .fetchAll(db)
            let inventories = try MonitoredSurface.allCases.reduce(
                into: [MonitoredSurface: [InventoryItem]]()
            ) { result, surface in
                result[surface] = try inventoryItems(
                    matching: InventoryPageRequest(surface: surface, limit: inventoryLimitPerSurface),
                    in: db
                )
            }
            let counts = try itemCounts(in: db)
            return WindowSnapshot(
                findings: findings,
                activity: activity,
                inventories: inventories,
                inventoryCountsBySurface: counts
            )
        }
    }

    func inventoryPage(_ pageRequest: InventoryPageRequest) throws -> InventoryPageSnapshot {
        try database.reader.read { db in
            let items = try inventoryItems(matching: pageRequest, in: db)
            let count = try inventoryCount(
                matching: pageRequest.searchText,
                surface: pageRequest.surface,
                in: db
            )
            return InventoryPageSnapshot(items: items, totalCount: count)
        }
    }

    func inventoryPage(
        for surface: MonitoredSurface,
        limit: Int,
        after cursor: InventoryPageCursor? = nil
    ) throws -> InventoryPageSnapshot {
        try inventoryPage(InventoryPageRequest(surface: surface, limit: limit, cursor: cursor))
    }

    func inventoryItemDetail(
        for item: InventoryItem,
        activityLimit: Int,
        findingLimit: Int
    ) throws -> InventoryItemDetailSnapshot {
        try database.reader.read { db in
            let findings = try Finding
                .filter(Column(ReadModelQueries.surface) == item.surface)
                .filter(Column(ReadModelQueries.itemID) == item.id)
                .order(Column(ReadModelQueries.timestamp).desc)
                .limit(findingLimit)
                .fetchAll(db)
            let activity = try ChangeEvent
                .filter(Column(ReadModelQueries.surface) == item.surface)
                .filter(Column(ReadModelQueries.itemID) == item.id)
                .order(Column(ReadModelQueries.timestamp).desc)
                .limit(activityLimit)
                .fetchAll(db)
            return InventoryItemDetailSnapshot(findings: findings, activity: activity)
        }
    }

    private func inventoryItems(
        matching pageRequest: InventoryPageRequest,
        in db: Database
    ) throws -> [InventoryItem] {
        if let query = pageRequest.searchText.ftsQuery {
            return try inventorySearch.items(matching: pageRequest, query: query, in: db)
        }
        return try inventoryRequest(surface: pageRequest.surface)
            .filter(cursor: pageRequest.cursor)
            .order(sql: ReadModelQueries.inventoryPageOrder)
            .limit(pageRequest.limit)
            .fetchAll(db)
    }

    private func inventoryCount(
        matching searchText: InventorySearchText,
        surface: MonitoredSurface,
        in db: Database
    ) throws -> Int {
        if let query = searchText.ftsQuery {
            return try inventorySearch.count(matching: query, surface: surface, in: db)
        }
        return try inventoryRequest(surface: surface).fetchCount(db)
    }

    private func inventoryRequest(surface: MonitoredSurface) -> QueryInterfaceRequest<InventoryItem> {
        InventoryItem.filter(Column(ReadModelQueries.surface) == surface)
    }

    private func itemCounts(in db: Database) throws -> [MonitoredSurface: Int] {
        let rows = try Row.fetchAll(db, sql: ReadModelQueries.inventoryCounts)
        var counts: [MonitoredSurface: Int] = [:]
        for row in rows {
            let rawSurface: String = row[ReadModelQueries.surface]
            guard let surface = MonitoredSurface(rawValue: rawSurface) else { continue }
            let count: Int = row[ReadModelQueries.itemCount]
            counts[surface] = count
        }
        return counts
    }
}
