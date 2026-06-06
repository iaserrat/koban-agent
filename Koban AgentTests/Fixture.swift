import Foundation
@testable import Koban_Agent

/// Shared builders so tests read as data, not boilerplate.
enum Fixture {
    static func item(
        surface: MonitoredSurface = .homebrew,
        kind: InventoryKind = .package,
        name: String,
        version: String? = nil,
        path: String? = nil,
        origin: String = "homebrew/core",
        installedOnRequest: Bool? = nil,
        detail: String? = nil
    ) -> InventoryItem {
        InventoryItem(
            surface: surface,
            kind: kind,
            name: name,
            version: version,
            path: path ?? "/tmp/\(name)",
            provenance: Provenance(origin: origin, installedOnRequest: installedOnRequest, detail: detail)
        )
    }

    static func finding(
        surface: MonitoredSurface = .claudeConfig,
        itemID: InventoryItem.ID? = nil,
        ruleID: String = "rule",
        itemName: String,
        timestamp: Date,
        severity: Severity = .notable
    ) -> Finding {
        Finding(
            id: UUID(),
            timestamp: timestamp,
            surface: surface,
            itemID: itemID ?? defaultItemID(surface: surface, itemName: itemName),
            ruleID: ruleID,
            title: "T",
            rationale: "R",
            severity: severity,
            itemName: itemName,
            evidence: FindingEvidence(
                path: "/tmp/\(itemName)",
                detail: nil,
                matchedField: nil,
                matchedValue: nil
            )
        )
    }

    static func event(
        surface: MonitoredSurface = .claudeConfig,
        kind: ChangeKind = .modified,
        itemID: InventoryItem.ID? = nil,
        itemName: String,
        detail: String = "uvx",
        timestamp: Date
    ) -> ChangeEvent {
        ChangeEvent(
            id: UUID(),
            timestamp: timestamp,
            surface: surface,
            kind: kind,
            itemID: itemID ?? defaultItemID(surface: surface, itemName: itemName),
            itemName: itemName,
            detail: detail
        )
    }

    /// A unique temporary directory, removed when `body` returns.
    static func withTemporaryDirectory<T>(_ body: (URL) async throws -> T) async rethrows -> T {
        let directory = FileManager.default.temporaryDirectory
            .appending(component: "koban-tests-" + UUID().uuidString, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try await body(directory)
    }

    private static func defaultItemID(surface: MonitoredSurface, itemName: String) -> InventoryItem.ID {
        InventoryItem(
            surface: surface,
            name: itemName,
            path: "/tmp/\(itemName)",
            provenance: Provenance(origin: "homebrew/core")
        ).id
    }
}
