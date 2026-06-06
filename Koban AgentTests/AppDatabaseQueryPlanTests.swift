import GRDB
import Testing
@testable import Koban_Agent

struct AppDatabaseQueryPlanTests {
    @Test
    func hotPathQueriesUseExpectedIndexesWithoutTempSorts() throws {
        let database = try AppDatabase(DatabaseQueue())
        let item = Fixture.item(surface: .homebrew, name: "openssl")

        try database.reader.read { db in
            try expectInventoryPagePlan(for: item, in: db)
            try expectItemActivityPlan(for: item, in: db)
            try expectItemFindingPlan(for: item, in: db)
            try expectInventorySearchPlan(for: item, in: db)
        }
    }

    private func expectInventoryPagePlan(for item: InventoryItem, in db: Database) throws {
        let plan = try queryPlanDetails(
            QueryPlanSQL.inventoryPage,
            arguments: [item.surface.rawValue, 10],
            in: db
        )
        #expect(containsDetail(QueryPlanDetails.usingIndex, in: plan))
        #expect(containsDetail(StorageNames.inventorySurfaceNamePathKindIndex, in: plan))
        #expect(containsDetail(QueryPlanDetails.tempBTree, in: plan) == false)
    }

    private func expectItemActivityPlan(for item: InventoryItem, in db: Database) throws {
        let plan = try queryPlanDetails(
            QueryPlanSQL.itemActivity,
            arguments: [item.surface.rawValue, item.id, 10],
            in: db
        )
        #expect(containsDetail(StorageNames.changeEventItemTimestampIndex, in: plan))
        #expect(containsDetail(QueryPlanDetails.tempBTree, in: plan) == false)
    }

    private func expectItemFindingPlan(for item: InventoryItem, in db: Database) throws {
        let plan = try queryPlanDetails(
            QueryPlanSQL.itemFindings,
            arguments: [item.surface.rawValue, item.id, 10],
            in: db
        )
        #expect(containsDetail(StorageNames.findingItemTimestampIndex, in: plan))
        #expect(containsDetail(QueryPlanDetails.tempBTree, in: plan) == false)
    }

    private func expectInventorySearchPlan(for item: InventoryItem, in db: Database) throws {
        let plan = try queryPlanDetails(
            QueryPlanSQL.inventorySearchPage,
            arguments: ["openss*", item.surface.rawValue, 10],
            in: db
        )
        #expect(containsDetail(QueryPlanDetails.virtualTable, in: plan))
        #expect(containsDetail(QueryPlanDetails.integerPrimaryKey, in: plan))
    }

    private func queryPlanDetails(
        _ sql: String,
        arguments: StatementArguments,
        in db: Database
    ) throws -> [String] {
        let rows = try Row.fetchAll(
            db,
            sql: QueryPlanSQL.explainPrefix + sql,
            arguments: arguments
        )
        return rows.map { row in
            row[QueryPlanSQL.detailColumn]
        }
    }

    private func containsDetail(_ expected: String, in details: [String]) -> Bool {
        details.contains { detail in
            detail.contains(expected)
        }
    }
}
