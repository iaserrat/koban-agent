import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - ReadModelStoreTests

struct ReadModelStoreTests {
    @Test
    func publishedStateReadsPanelDataAndCountsInOneSnapshot() throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let events = EventStore(database: database)
        let health = HealthStore(database: database)
        let store = ReadModelStore(database: database)
        let older = Date(timeIntervalSince1970: 1)
        let newer = Date(timeIntervalSince1970: 2)

        try inventory.replace(
            [
                Fixture.item(surface: .homebrew, name: "openssl"),
                Fixture.item(surface: .homebrew, name: "wget")
            ],
            for: .homebrew
        )
        try inventory.replace(
            [Fixture.item(surface: .claudeConfig, kind: .mcpServer, name: "remote")],
            for: .claudeConfig
        )
        try events.append(events: [
            Fixture.event(surface: .homebrew, itemName: "openssl", timestamp: older),
            Fixture.event(surface: .claudeConfig, itemName: "remote", timestamp: newer)
        ])
        try events.append(findings: [
            Fixture.finding(itemName: "remote", timestamp: newer)
        ])
        try health.markScanSucceeded(
            .homebrew,
            itemCount: 2,
            durationMilliseconds: 4,
            at: newer
        )

        let snapshot = try store.publishedState(eventLimit: 1, findingLimit: 1)

        #expect(snapshot.recentEvents.map(\.itemName) == ["remote"])
        #expect(snapshot.recentFindings.map(\.itemName) == ["remote"])
        #expect(snapshot.healthBySurface[.homebrew]?.itemCount == 2)
        #expect(snapshot.itemCountsBySurface[.homebrew] == 2)
        #expect(snapshot.itemCountsBySurface[.claudeConfig] == 1)
    }

    @Test
    func windowSnapshotReadsBoundedOrderedWindowModel() throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let events = EventStore(database: database)
        let store = ReadModelStore(database: database)
        let oldest = Date(timeIntervalSince1970: 1)
        let middle = Date(timeIntervalSince1970: 2)
        let newest = Date(timeIntervalSince1970: 3)

        try inventory.replace(
            [
                Fixture.item(surface: .homebrew, name: "zsh"),
                Fixture.item(surface: .homebrew, name: "openssl"),
                Fixture.item(surface: .homebrew, name: "wget")
            ],
            for: .homebrew
        )
        try events.append(events: [
            Fixture.event(surface: .homebrew, itemName: "openssl", timestamp: oldest),
            Fixture.event(surface: .homebrew, itemName: "wget", timestamp: middle),
            Fixture.event(surface: .homebrew, itemName: "zsh", timestamp: newest)
        ])
        try events.append(findings: [
            Fixture.finding(surface: .homebrew, itemName: "openssl", timestamp: oldest),
            Fixture.finding(surface: .homebrew, itemName: "wget", timestamp: middle),
            Fixture.finding(surface: .homebrew, itemName: "zsh", timestamp: newest)
        ])

        let snapshot = try store.windowSnapshot(
            activityLimit: 2,
            findingLimit: 2,
            inventoryLimitPerSurface: 2
        )

        #expect(snapshot.activity.map(\.itemName) == ["zsh", "wget"])
        #expect(snapshot.findings.map(\.itemName) == ["zsh", "wget"])
        #expect(snapshot.inventories[.homebrew]?.map(\.name) == ["openssl", "wget"])
        #expect(snapshot.inventoryCountsBySurface[.homebrew] == 3)
    }

    @Test
    func inventoryItemDetailReadsOnlySelectedItemWithLimits() throws {
        let database = try AppDatabase(DatabaseQueue())
        let events = EventStore(database: database)
        let store = ReadModelStore(database: database)
        let selected = Fixture.item(surface: .homebrew, name: "openssl", path: "/opt/homebrew/openssl")
        let other = Fixture.item(surface: .homebrew, name: "openssl", path: "/usr/local/openssl")
        let oldest = Date(timeIntervalSince1970: 1)
        let middle = Date(timeIntervalSince1970: 2)
        let newest = Date(timeIntervalSince1970: 3)

        try events.append(events: [
            event(for: selected, at: oldest),
            event(for: selected, at: newest),
            event(for: other, at: middle)
        ])
        try events.append(findings: [
            finding(for: selected, at: oldest),
            finding(for: selected, at: newest),
            finding(for: other, at: middle)
        ])

        let snapshot = try store.inventoryItemDetail(
            for: selected,
            activityLimit: 1,
            findingLimit: 1
        )

        #expect(snapshot.activity.map(\.itemID) == [selected.id])
        #expect(snapshot.activity.map(\.timestamp) == [newest])
        #expect(snapshot.findings.map(\.itemID) == [selected.id])
        #expect(snapshot.findings.map(\.timestamp) == [newest])
    }

    @Test
    func inventoryPageReadsStableCursorSlices() throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let store = ReadModelStore(database: database)

        try inventory.replace(
            [
                Fixture.item(surface: .homebrew, kind: .package, name: "delta"),
                Fixture.item(surface: .homebrew, kind: .package, name: "alpha", path: "/tmp/z"),
                Fixture.item(surface: .homebrew, kind: .mcpServer, name: "alpha", path: "/tmp/z"),
                Fixture.item(surface: .homebrew, kind: .package, name: "charlie"),
                Fixture.item(surface: .homebrew, kind: .package, name: "bravo")
            ],
            for: .homebrew
        )
        try inventory.replace(
            [Fixture.item(surface: .claudeConfig, kind: .mcpServer, name: "remote")],
            for: .claudeConfig
        )

        let firstPage = try store.inventoryPage(for: .homebrew, limit: 2)
        let secondPage = try store.inventoryPage(for: .homebrew, limit: 2, after: firstPage.nextCursor)
        let thirdPage = try store.inventoryPage(for: .homebrew, limit: 2, after: secondPage.nextCursor)

        #expect(firstPage.items.map(\.id) == [
            "homebrew/mcpServer//tmp/z/alpha",
            "homebrew/package//tmp/z/alpha"
        ])
        #expect(secondPage.items.map(\.name) == ["bravo", "charlie"])
        #expect(thirdPage.items.map(\.name) == ["delta"])
        #expect(thirdPage.nextCursor == InventoryPageCursor(item: thirdPage.items[0]))
    }
}

extension ReadModelStoreTests {
    private func event(for item: InventoryItem, at timestamp: Date) -> ChangeEvent {
        Fixture.event(
            surface: item.surface,
            itemID: item.id,
            itemName: item.name,
            timestamp: timestamp
        )
    }

    private func finding(for item: InventoryItem, at timestamp: Date) -> Finding {
        Fixture.finding(
            surface: item.surface,
            itemID: item.id,
            itemName: item.name,
            timestamp: timestamp
        )
    }
}
