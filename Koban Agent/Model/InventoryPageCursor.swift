struct InventoryPageCursor: Codable, Hashable {
    let name: String
    let path: String
    let kind: InventoryKind

    init(name: String, path: String, kind: InventoryKind) {
        self.name = name
        self.path = path
        self.kind = kind
    }

    init(item: InventoryItem) {
        self.init(name: item.name, path: item.path, kind: item.kind)
    }
}
