// MARK: - RetentionQueries

enum RetentionQueries {
    static let pruneChangeEvents = """
    DELETE FROM changeEvent
    WHERE id IN (
        SELECT id
        FROM changeEvent
        ORDER BY timestamp DESC, id DESC
        LIMIT -1 OFFSET ?
    )
    """
    static let pruneFindings = """
    DELETE FROM finding
    WHERE id IN (
        SELECT id
        FROM finding
        ORDER BY timestamp DESC, id DESC
        LIMIT -1 OFFSET ?
    )
    """
}
