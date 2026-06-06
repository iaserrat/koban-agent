import Foundation
import Testing
@testable import Koban_Agent

// MARK: - WindowDataModelTests

@MainActor
struct WindowDataModelTests {
    @Test
    func failedReloadRecordsReadModelFailureAndPreservesLastGoodState() async {
        let item = Fixture.item(surface: .homebrew, name: WindowDataModelFixture.itemName)
        let event = Fixture.event(
            surface: .homebrew,
            itemID: item.id,
            itemName: item.name,
            timestamp: WindowDataModelFixture.timestamp
        )
        let provider = WindowSnapshotProvider(
            .success(WindowDataModelFixture.snapshot(item: item, event: event))
        )
        let model = WindowDataModel(
            operations: WindowDataModelFixture.operations(windowSnapshot: provider.load)
        )
        await model.reload()

        provider.set(.failure(.readModelUnavailable))
        await model.reload()

        #expect(model.readModelError == String(describing: WindowDataModelFailure.readModelUnavailable))
        #expect(model.activity == [event])
        #expect(model.items(for: .homebrew) == [item])
    }

    @Test
    func failedSearchRecordsReadModelFailureAndPreservesCurrentInventory() async {
        let item = Fixture.item(surface: .homebrew, name: WindowDataModelFixture.itemName)
        let model = WindowDataModel(
            operations: WindowDataModelFixture.operations(
                windowSnapshot: { WindowDataModelFixture.snapshot(item: item) },
                inventoryPage: { _ in throw WindowDataModelFailure.readModelUnavailable }
            )
        )
        await model.reload()

        await model.searchInventory(WindowDataModelFixture.searchText, for: .homebrew)

        #expect(model.readModelError == String(describing: WindowDataModelFailure.readModelUnavailable))
        #expect(model.items(for: .homebrew) == [item])
    }

    @Test
    func successfulReloadClearsPreviousReadModelFailure() async {
        let item = Fixture.item(surface: .homebrew, name: WindowDataModelFixture.itemName)
        let provider = WindowSnapshotProvider(.failure(.readModelUnavailable))
        let model = WindowDataModel(
            operations: WindowDataModelFixture.operations(windowSnapshot: provider.load)
        )
        await model.reload()

        provider.set(.success(WindowDataModelFixture.snapshot(item: item)))
        await model.reload()

        #expect(model.readModelError == nil)
        #expect(model.items(for: .homebrew) == [item])
    }
}

// MARK: - WindowDataModelFixture

private enum WindowDataModelFixture {
    static let itemName = "ripgrep"
    static let searchText = "rg"
    static let timestamp = Date(timeIntervalSince1970: timestampSeconds)
    static let timestampSeconds: TimeInterval = 1
    static let itemCount = 1

    static func operations(
        windowSnapshot: @escaping @Sendable () throws -> WindowSnapshot,
        inventoryPage: @escaping @Sendable (
            InventoryPageRequest
        ) throws -> InventoryPageSnapshot = emptyInventoryPage,
        inventoryItemDetail: @escaping @Sendable (
            InventoryItem,
            Int,
            Int
        ) throws -> InventoryItemDetailSnapshot = inventoryItemDetail
    ) -> WindowReadModelOperations {
        WindowReadModelOperations(
            windowSnapshot: windowSnapshot,
            inventoryPage: inventoryPage,
            inventoryItemDetail: inventoryItemDetail
        )
    }

    static func snapshot(item: InventoryItem, event: ChangeEvent? = nil) -> WindowSnapshot {
        WindowSnapshot(
            findings: [],
            activity: event.map { [$0] } ?? [],
            inventories: [.homebrew: [item]],
            inventoryCountsBySurface: [.homebrew: itemCount]
        )
    }

    static func emptyInventoryPage(_: InventoryPageRequest) throws -> InventoryPageSnapshot {
        .empty
    }

    static func inventoryItemDetail(
        _: InventoryItem,
        _: Int,
        _: Int
    ) throws -> InventoryItemDetailSnapshot {
        .empty
    }
}

// MARK: - WindowDataModelFailure

private enum WindowDataModelFailure: Error {
    case readModelUnavailable
}

// MARK: - WindowSnapshotProvider

private final class WindowSnapshotProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<WindowSnapshot, WindowDataModelFailure>

    init(_ result: Result<WindowSnapshot, WindowDataModelFailure>) {
        self.result = result
    }

    func set(_ result: Result<WindowSnapshot, WindowDataModelFailure>) {
        lock.lock()
        defer { lock.unlock() }
        self.result = result
    }

    func load() throws -> WindowSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return try result.get()
    }
}
