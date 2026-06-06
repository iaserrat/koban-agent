// MARK: - ReadModelQueries

enum ReadModelQueries {
    static let inventoryCounts = """
    SELECT surface, COUNT(*) AS itemCount
    FROM inventoryItem
    GROUP BY surface
    """
    static let inventoryPageAfterCursor = """
    (name > ? COLLATE NOCASE
    OR (name = ? COLLATE NOCASE AND path > ? COLLATE NOCASE)
    OR (name = ? COLLATE NOCASE AND path = ? COLLATE NOCASE AND kind > ?))
    """
    static let inventoryPageOrder = "name COLLATE NOCASE, path COLLATE NOCASE, kind"
    static let inventorySearchPage = """
    SELECT item.*
    FROM inventorySearch search
    JOIN inventoryItem item ON item.rowid = search.rowid
    WHERE inventorySearch MATCH ?
      AND item.surface = ?
    """
    static let inventorySearchPageAfterCursor = """
      AND (item.name > ? COLLATE NOCASE
       OR (item.name = ? COLLATE NOCASE AND item.path > ? COLLATE NOCASE)
       OR (item.name = ? COLLATE NOCASE AND item.path = ? COLLATE NOCASE AND item.kind > ?))
    """
    static let inventorySearchPageOrder = """
    ORDER BY item.name COLLATE NOCASE, item.path COLLATE NOCASE, item.kind
    LIMIT ?
    """
    static let inventorySearchCount = """
    SELECT COUNT(*)
    FROM inventorySearch search
    JOIN inventoryItem item ON item.rowid = search.rowid
    WHERE inventorySearch MATCH ?
      AND item.surface = ?
    """
    static let itemCount = "itemCount"
    static let itemID = "itemID"
    static let kind = "kind"
    static let name = "name"
    static let path = "path"
    static let surface = "surface"
    static let timestamp = "timestamp"
}
