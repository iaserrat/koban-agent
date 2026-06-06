// MARK: - WindowReadModelOperations

struct WindowReadModelOperations {
    let windowSnapshot: @Sendable () throws -> WindowSnapshot
    let inventoryPage: @Sendable (InventoryPageRequest) throws -> InventoryPageSnapshot
    let inventoryItemDetail: @Sendable (
        InventoryItem,
        Int,
        Int
    ) throws -> InventoryItemDetailSnapshot

    init(readModels: ReadModelStore) {
        windowSnapshot = {
            try readModels.windowSnapshot(
                activityLimit: WindowReadLimits.activity,
                findingLimit: WindowReadLimits.findings,
                inventoryLimitPerSurface: WindowReadLimits.inventoryItemsPerSurface
            )
        }
        inventoryPage = { request in
            try readModels.inventoryPage(request)
        }
        inventoryItemDetail = { item, activityLimit, findingLimit in
            try readModels.inventoryItemDetail(
                for: item,
                activityLimit: activityLimit,
                findingLimit: findingLimit
            )
        }
    }

    init(
        windowSnapshot: @escaping @Sendable () throws -> WindowSnapshot,
        inventoryPage: @escaping @Sendable (InventoryPageRequest) throws -> InventoryPageSnapshot,
        inventoryItemDetail: @escaping @Sendable (
            InventoryItem,
            Int,
            Int
        ) throws -> InventoryItemDetailSnapshot
    ) {
        self.windowSnapshot = windowSnapshot
        self.inventoryPage = inventoryPage
        self.inventoryItemDetail = inventoryItemDetail
    }
}
