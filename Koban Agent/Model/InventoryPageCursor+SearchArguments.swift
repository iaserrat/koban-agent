import GRDB

extension InventoryPageCursor {
    var searchArguments: StatementArguments {
        [
            name,
            name,
            path,
            name,
            path,
            kind.rawValue
        ]
    }
}
