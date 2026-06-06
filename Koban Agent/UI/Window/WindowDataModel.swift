import Observation

// MARK: - WindowDataModel

/// The extended window's data source. `AppState` is the panel's small glance cache; this loads
/// the full, ordered lists straight from the database when the window is open, so the window is
/// never bounded by the panel's caps. The blocking reads run off the main actor; results publish
/// on it (see CLAUDE.md - IO lives at the edges).
@MainActor
@Observable
final class WindowDataModel {
    private let operations: WindowReadModelOperations

    private(set) var findingGroups: [FindingGroup] = []
    private(set) var activity: [ChangeEvent] = []
    private(set) var inventories: [MonitoredSurface: [InventoryItem]] = [:]
    private(set) var inventoryCountsBySurface: [MonitoredSurface: Int] = [:]
    private(set) var inventorySearchTextBySurface: [MonitoredSurface: String] = [:]
    private(set) var readModelError: String?
    private var filteredInventoryCountsBySurface: [MonitoredSurface: Int] = [:]
    private var loadingInventorySurfaces: Set<MonitoredSurface> = []
    private var itemDetailsByID: [InventoryItem.ID: InventoryItemDetailSnapshot] = [:]

    init(readModels: ReadModelStore) {
        operations = WindowReadModelOperations(readModels: readModels)
    }

    init(operations: WindowReadModelOperations) {
        self.operations = operations
    }

    func reload() async {
        let windowSnapshot = operations.windowSnapshot
        let result = await Task.detached(priority: .userInitiated) {
            Result { try windowSnapshot() }
        }.value
        guard case let .success(snapshot) = result else {
            recordFailure(result)
            return
        }
        findingGroups = FindingGroup.grouped(snapshot.findings)
        activity = snapshot.activity
        inventories = snapshot.inventories
        inventoryCountsBySurface = snapshot.inventoryCountsBySurface
        readModelError = nil
        filteredInventoryCountsBySurface.removeAll()
        loadingInventorySurfaces.removeAll()
        itemDetailsByID = itemDetailsByID.filter { id, _ in
            snapshot.inventories.values.contains { items in
                items.contains { $0.id == id }
            }
        }
    }

    /// The loaded lists bundled for the pure stream-row builder.
    var monitorData: MonitorData {
        MonitorData(activity: activity, findingGroups: findingGroups, inventories: inventories)
    }

    /// The surfaces with at least one open finding, so the by-surface bars can colour them amber.
    var flaggedSurfaces: Set<MonitoredSurface> {
        Set(findingGroups.map(\.representative.surface))
    }

    func findingGroup(id: FindingGroup.ID?) -> FindingGroup? {
        guard let id else { return nil }
        return findingGroups.first { $0.id == id }
    }

    func items(for surface: MonitoredSurface) -> [InventoryItem] {
        inventories[surface] ?? []
    }

    func inventoryCount(for surface: MonitoredSurface) -> Int {
        if hasInventorySearchText(for: surface) {
            return filteredInventoryCountsBySurface[surface] ?? items(for: surface).count
        }
        return inventoryCountsBySurface[surface] ?? items(for: surface).count
    }

    func inventorySearchText(for surface: MonitoredSurface) -> String {
        inventorySearchTextBySurface[surface] ?? InventorySearchText.empty.rawValue
    }

    func hasInventorySearchText(for surface: MonitoredSurface) -> Bool {
        InventorySearchText(inventorySearchText(for: surface)).isEmpty == false
    }

    func loadedInventoryCount(for surface: MonitoredSurface) -> Int {
        items(for: surface).count
    }

    func hasMoreInventory(for surface: MonitoredSurface) -> Bool {
        loadedInventoryCount(for: surface) < inventoryCount(for: surface)
    }

    func isLoadingInventory(for surface: MonitoredSurface) -> Bool {
        loadingInventorySurfaces.contains(surface)
    }

    func loadMoreInventory(for surface: MonitoredSurface) async {
        guard hasMoreInventory(for: surface),
              loadingInventorySurfaces.contains(surface) == false
        else { return }
        loadingInventorySurfaces.insert(surface)
        defer { loadingInventorySurfaces.remove(surface) }

        let cursor = items(for: surface).last.map(InventoryPageCursor.init(item:))
        let request = inventoryPageRequest(for: surface, cursor: cursor)
        let inventoryPage = operations.inventoryPage
        let result = await Task.detached(priority: .userInitiated) {
            Result { try inventoryPage(request) }
        }.value
        guard case let .success(snapshot) = result else {
            recordFailure(result)
            return
        }
        readModelError = nil
        filteredInventoryCountsBySurface[surface] = snapshot.totalCount
        let existingIDs = Set(items(for: surface).map(\.id))
        let newItems = snapshot.items.filter { existingIDs.contains($0.id) == false }
        inventories[surface, default: []].append(contentsOf: newItems)
    }

    func searchInventory(_ text: String, for surface: MonitoredSurface) async {
        let searchText = InventorySearchText(text)
        guard inventorySearchText(for: surface) != searchText.rawValue else { return }
        inventorySearchTextBySurface[surface] = searchText.rawValue
        loadingInventorySurfaces.remove(surface)

        let request = InventoryPageRequest(
            surface: surface,
            limit: WindowReadLimits.inventoryItemsPerSurface,
            searchText: searchText
        )
        let inventoryPage = operations.inventoryPage
        let result = await Task.detached(priority: .userInitiated) {
            Result { try inventoryPage(request) }
        }.value
        guard case let .success(snapshot) = result else {
            recordFailure(result)
            return
        }
        readModelError = nil
        inventories[surface] = snapshot.items
        filteredInventoryCountsBySurface[surface] = snapshot.totalCount
    }

    func inventoryItem(id: InventoryItem.ID?, surface: MonitoredSurface) -> InventoryItem? {
        guard let id else { return nil }
        return items(for: surface).first { $0.id == id }
    }

    func loadDetail(for item: InventoryItem) async {
        let inventoryItemDetail = operations.inventoryItemDetail
        let result = await Task.detached(priority: .userInitiated) {
            Result {
                try inventoryItemDetail(
                    item,
                    WindowReadLimits.activity,
                    WindowReadLimits.findings
                )
            }
        }.value
        guard case let .success(snapshot) = result else {
            recordFailure(result)
            return
        }
        readModelError = nil
        itemDetailsByID[item.id] = snapshot
    }

    /// The most recent finding per indicator raised against a given item, for the inventory
    /// detail pane's "why this might matter" section.
    func findings(for item: InventoryItem) -> [Finding] {
        itemDetailsByID[item.id]?.findings ?? []
    }

    /// Recent raw changes to a given item, for the inventory detail pane.
    func activity(for item: InventoryItem) -> [ChangeEvent] {
        itemDetailsByID[item.id]?.activity ?? []
    }
}

// MARK: - Private

extension WindowDataModel {
    private func inventoryPageRequest(
        for surface: MonitoredSurface,
        cursor: InventoryPageCursor?
    ) -> InventoryPageRequest {
        InventoryPageRequest(
            surface: surface,
            limit: WindowReadLimits.inventoryItemsPerSurface,
            searchText: InventorySearchText(inventorySearchText(for: surface)),
            cursor: cursor
        )
    }

    private func recordFailure<T>(_ result: Result<T, any Error>) {
        guard case let .failure(error) = result else { return }
        readModelError = String(describing: error)
    }
}
