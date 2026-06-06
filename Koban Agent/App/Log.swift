import OSLog

/// Centralised `Logger` instances, one per subsystem area. Using the unified logging system
/// keeps diagnostics inspectable in Console.app without printing to stdout.
enum Log {
    private static let subsystem = "com.kobanhq.Koban-Agent"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let configuration = Logger(subsystem: subsystem, category: "configuration")
    static let watching = Logger(subsystem: subsystem, category: "watching")
    static let collection = Logger(subsystem: subsystem, category: "collection")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let engine = Logger(subsystem: subsystem, category: "engine")
    static let sync = Logger(subsystem: subsystem, category: "sync")
}
