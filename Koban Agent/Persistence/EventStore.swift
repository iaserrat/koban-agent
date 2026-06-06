import Foundation
import GRDB

/// Appends change events and findings to the log and reads back the most recent of each for
/// the UI. The activity feed and the findings list are both time-ordered, newest first.
struct EventStore {
    let database: AppDatabase

    func append(events: [ChangeEvent]) throws {
        try database.writer.write { db in
            for event in events {
                try event.insert(db)
            }
        }
    }

    func append(findings: [Finding]) throws {
        try database.writer.write { db in
            for finding in findings {
                try finding.insert(db)
            }
        }
    }

    func recentEvents(limit: Int) throws -> [ChangeEvent] {
        try database.reader.read { db in
            try ChangeEvent.order(Column("timestamp").desc).limit(limit).fetchAll(db)
        }
    }

    func recentFindings(limit: Int) throws -> [Finding] {
        try database.reader.read { db in
            try Finding.order(Column("timestamp").desc).limit(limit).fetchAll(db)
        }
    }

    /// The full change log, newest first. The window shows everything; only the panel is capped.
    func allEvents() throws -> [ChangeEvent] {
        try database.reader.read { db in
            try ChangeEvent.order(Column("timestamp").desc).fetchAll(db)
        }
    }

    /// Every finding, newest first. Grouped for display by the window's data model.
    func allFindings() throws -> [Finding] {
        try database.reader.read { db in
            try Finding.order(Column("timestamp").desc).fetchAll(db)
        }
    }
}
