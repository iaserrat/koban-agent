import Foundation
import Testing
@testable import Koban_Agent

struct MonitorRowBuilderTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func activityScopeProjectsEveryChangeAsAChangeBadge() {
        let brew = Fixture.event(surface: .homebrew, kind: .added, itemName: "ripgrep", timestamp: t0)
        let npm = Fixture.event(
            surface: .javascriptPackages, kind: .modified, itemName: "left-pad", timestamp: t0
        )

        let rows = MonitorRowBuilder.rows(
            scope: .activity,
            data: MonitorData(activity: [brew, npm], findingGroups: [], inventories: [:]),
            surfaceFilter: nil,
            searchText: ""
        )

        #expect(rows.map(\.name) == ["ripgrep", "left-pad"])
        #expect(rows.first?.badge == .change(.added))
        #expect(rows.allSatisfy { $0.severity == nil })
    }

    @Test
    func findingsScopeProjectsOneRowPerGroupWithItsSeverity() {
        let finding = Fixture.finding(
            surface: .claudeConfig, itemName: "serena", timestamp: t0, severity: .suspicious
        )

        let rows = MonitorRowBuilder.rows(
            scope: .findings,
            data: MonitorData(activity: [], findingGroups: FindingGroup.grouped([finding]), inventories: [:]),
            surfaceFilter: nil,
            searchText: ""
        )

        #expect(rows.count == 1)
        #expect(rows.first?.severity == .suspicious)
        #expect(rows.first?.badge == .rule("T"))
    }

    @Test
    func activityRowInheritsTheWorstSeverityRaisedAgainstItsItem() {
        let item = Fixture.item(surface: .homebrew, name: "ripgrep")
        let event = Fixture.event(
            surface: .homebrew, kind: .added, itemID: item.id, itemName: "ripgrep", timestamp: t0
        )
        let notable = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "a",
            itemName: "ripgrep",
            timestamp: t0,
            severity: .notable
        )
        let suspicious = Fixture.finding(
            surface: .homebrew,
            itemID: item.id,
            ruleID: "b",
            itemName: "ripgrep",
            timestamp: t0,
            severity: .suspicious
        )

        let rows = MonitorRowBuilder.rows(
            scope: .activity,
            data: MonitorData(
                activity: [event],
                findingGroups: FindingGroup.grouped([suspicious, notable]),
                inventories: [.homebrew: [item]]
            ),
            surfaceFilter: nil,
            searchText: ""
        )

        #expect(rows.first?.severity == .suspicious)
        // The joined item enriches the row with the path the change event lacks.
        #expect(rows.first?.path == item.path)
    }

    @Test
    func surfaceFilterKeepsOnlyTheMatchingSurface() {
        let brew = Fixture.event(surface: .homebrew, itemName: "ripgrep", timestamp: t0)
        let npm = Fixture.event(surface: .javascriptPackages, itemName: "left-pad", timestamp: t0)

        let rows = MonitorRowBuilder.rows(
            scope: .activity,
            data: MonitorData(activity: [brew, npm], findingGroups: [], inventories: [:]),
            surfaceFilter: .homebrew,
            searchText: ""
        )

        #expect(rows.map(\.name) == ["ripgrep"])
    }

    @Test
    func searchMatchesNameAndPathCaseInsensitively() {
        let brew = Fixture.event(surface: .homebrew, itemName: "ripgrep", timestamp: t0)
        let npm = Fixture.event(surface: .javascriptPackages, itemName: "left-pad", timestamp: t0)

        let rows = MonitorRowBuilder.rows(
            scope: .activity,
            data: MonitorData(activity: [brew, npm], findingGroups: [], inventories: [:]),
            surfaceFilter: nil,
            searchText: "RIP"
        )

        #expect(rows.map(\.name) == ["ripgrep"])
    }

    @Test
    func inventoryScopeFlattensSurfacesInStableOrder() {
        let brew = Fixture.item(surface: .homebrew, name: "ripgrep")
        let npm = Fixture.item(surface: .javascriptPackages, name: "left-pad", origin: "npm")

        let rows = MonitorRowBuilder.rows(
            scope: .inventory,
            data: MonitorData(
                activity: [],
                findingGroups: [],
                inventories: [.javascriptPackages: [npm], .homebrew: [brew]]
            ),
            surfaceFilter: nil,
            searchText: ""
        )

        // Sorted by surface raw value, regardless of dictionary order.
        #expect(rows.map(\.surface) == [.homebrew, .javascriptPackages])
        #expect(rows.allSatisfy { $0.badge == .blank })
    }
}
