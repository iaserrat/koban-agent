// MARK: - DatabaseRuntimeQueries

enum DatabaseRuntimeQueries {
    static let synchronousNormal = "PRAGMA synchronous = NORMAL"
    static let readJournalMode = "PRAGMA journal_mode"
    static let readSynchronous = "PRAGMA synchronous"
    static let journalModeWal = "wal"
    static let checkpointScratchTable = "checkpointScratch"
}
