struct ScanTelemetry: Codable, Hashable {
    var itemCount: Int
    var eventCount: Int
    var findingCount: Int
    var addedItemCount: Int
    var modifiedItemCount: Int
    var removedItemCount: Int

    init(
        itemCount: Int = 0,
        eventCount: Int = 0,
        findingCount: Int = 0,
        addedItemCount: Int = 0,
        modifiedItemCount: Int = 0,
        removedItemCount: Int = 0
    ) {
        self.itemCount = itemCount
        self.eventCount = eventCount
        self.findingCount = findingCount
        self.addedItemCount = addedItemCount
        self.modifiedItemCount = modifiedItemCount
        self.removedItemCount = removedItemCount
    }

    init(items: [InventoryItem], events: [ChangeEvent], findings: [Finding]) {
        var addedItemCount = 0
        var modifiedItemCount = 0
        var removedItemCount = 0

        for event in events {
            switch event.kind {
            case .added:
                addedItemCount += 1
            case .modified:
                modifiedItemCount += 1
            case .removed:
                removedItemCount += 1
            }
        }

        self.init(
            itemCount: items.count,
            eventCount: events.count,
            findingCount: findings.count,
            addedItemCount: addedItemCount,
            modifiedItemCount: modifiedItemCount,
            removedItemCount: removedItemCount
        )
    }
}
