enum SyncOutboxBuildError: Error {
    case missingInventoryItem(InventoryItem.ID)
}
