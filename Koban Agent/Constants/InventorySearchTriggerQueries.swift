enum InventorySearchTriggerQueries {
    static let insertTriggerName = "inventoryItemInventorySearchInsertTrigger"
    static let updateTriggerName = "inventoryItemInventorySearchUpdateTrigger"
    static let deleteTriggerName = "inventoryItemInventorySearchDeleteTrigger"
    static let deleteCommand = "delete"
    static let itemSearchTextExpression = """
    NEW.name || ' ' ||
    NEW.path || ' ' ||
    NEW.kind || ' ' ||
    COALESCE(NEW.version, '') || ' ' ||
    NEW.provenance
    """
    static let createInsertTrigger = """
    CREATE TRIGGER \(insertTriggerName)
    AFTER INSERT ON \(InventoryItem.databaseTableName)
    BEGIN
        INSERT INTO \(StorageNames.inventorySearchTable)(rowid, searchText)
        VALUES (NEW.rowid, \(itemSearchTextExpression));
    END
    """
    static let createUpdateTrigger = """
    CREATE TRIGGER \(updateTriggerName)
    AFTER UPDATE ON \(InventoryItem.databaseTableName)
    BEGIN
        INSERT INTO \(StorageNames.inventorySearchTable)(
            \(StorageNames.inventorySearchTable),
            rowid,
            searchText
        )
        VALUES ('\(deleteCommand)', OLD.rowid, \(oldItemSearchTextExpression));
        INSERT INTO \(StorageNames.inventorySearchTable)(rowid, searchText)
        VALUES (NEW.rowid, \(itemSearchTextExpression));
    END
    """
    static let createDeleteTrigger = """
    CREATE TRIGGER \(deleteTriggerName)
    AFTER DELETE ON \(InventoryItem.databaseTableName)
    BEGIN
        INSERT INTO \(StorageNames.inventorySearchTable)(
            \(StorageNames.inventorySearchTable),
            rowid,
            searchText
        )
        VALUES ('\(deleteCommand)', OLD.rowid, \(oldItemSearchTextExpression));
    END
    """
    static let allCreateStatements = [
        createInsertTrigger,
        createUpdateTrigger,
        createDeleteTrigger
    ]

    private static let oldItemSearchTextExpression = """
    OLD.name || ' ' ||
    OLD.path || ' ' ||
    OLD.kind || ' ' ||
    COALESCE(OLD.version, '') || ' ' ||
    OLD.provenance
    """
}
