import GRDB
import Testing
@testable import Koban_Agent

struct ReadModelStoreInventorySearchTests {
    @Test
    func inventoryPageSearchesIndexedTokensWithCursor() throws {
        let database = try AppDatabase(DatabaseQueue())
        let inventory = InventoryRepository(database: database)
        let store = ReadModelStore(database: database)

        try inventory.replace(
            [
                Fixture.item(surface: .homebrew, name: "Alpha"),
                Fixture.item(surface: .homebrew, name: "alphabet"),
                Fixture.item(surface: .homebrew, name: "alpine"),
                Fixture.item(surface: .homebrew, name: "bravo"),
                Fixture.item(surface: .homebrew, name: "zap", path: "/tmp/alpha-path")
            ],
            for: .homebrew
        )

        let firstPage = try store.inventoryPage(InventoryPageRequest(
            surface: .homebrew,
            limit: 2,
            searchText: InventorySearchText("alph")
        ))
        let secondPage = try store.inventoryPage(InventoryPageRequest(
            surface: .homebrew,
            limit: 2,
            searchText: InventorySearchText("alph"),
            cursor: firstPage.nextCursor
        ))

        #expect(firstPage.totalCount == 3)
        #expect(firstPage.items.map(\.name) == ["Alpha", "alphabet"])
        #expect(secondPage.totalCount == 3)
        #expect(secondPage.items.map(\.name) == ["zap"])
    }
}
