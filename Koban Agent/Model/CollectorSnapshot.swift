struct CollectorSnapshot {
    var items: [InventoryItem]
    var issues: [CollectorIssue]

    init(items: [InventoryItem], issues: [CollectorIssue] = []) {
        self.items = items
        self.issues = issues
    }
}
