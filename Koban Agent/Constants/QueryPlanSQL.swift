enum QueryPlanSQL {
    static let detailColumn = "detail"
    static let explainPrefix = "EXPLAIN QUERY PLAN "
    static let inventoryPage = """
    SELECT *
    FROM inventoryItem
    WHERE surface = ?
    ORDER BY name COLLATE NOCASE, path COLLATE NOCASE, kind
    LIMIT ?
    """
    static let inventorySearchPage = """
    SELECT item.*
    FROM inventorySearch search
    JOIN inventoryItem item ON item.rowid = search.rowid
    WHERE inventorySearch MATCH ?
      AND item.surface = ?
    ORDER BY item.name COLLATE NOCASE, item.path COLLATE NOCASE, item.kind
    LIMIT ?
    """
    static let itemActivity = """
    SELECT *
    FROM changeEvent
    WHERE surface = ?
      AND itemID = ?
    ORDER BY timestamp DESC
    LIMIT ?
    """
    static let itemFindings = """
    SELECT *
    FROM finding
    WHERE surface = ?
      AND itemID = ?
    ORDER BY timestamp DESC
    LIMIT ?
    """
}
