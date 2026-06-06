// MARK: - PersistenceSettings

struct PersistenceSettings: Codable, Hashable {
    var maxStoredEvents: Int
    var maxStoredFindings: Int
}
