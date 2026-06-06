import Testing
@testable import Koban_Agent

struct InventoryDifferTests {
    @Test
    func reportsNothingWhenSnapshotsMatch() {
        let items = [Fixture.item(name: "ripgrep", version: "14.0")]
        #expect(InventoryDiffer.diff(previous: items, current: items).isEmpty)
    }

    @Test
    func detectsAdditions() {
        let changes = InventoryDiffer.diff(
            previous: [],
            current: [Fixture.item(name: "ripgrep")]
        )
        #expect(changes.count == 1)
        #expect(changes.first?.kind == .added)
        #expect(changes.first?.item.name == "ripgrep")
    }

    @Test
    func detectsRemovals() {
        let changes = InventoryDiffer.diff(
            previous: [Fixture.item(name: "ripgrep")],
            current: []
        )
        #expect(changes.first?.kind == .removed)
    }

    @Test
    func detectsVersionChangeAsModified() {
        let changes = InventoryDiffer.diff(
            previous: [Fixture.item(name: "ripgrep", version: "13.0")],
            current: [Fixture.item(name: "ripgrep", version: "14.0")]
        )
        #expect(changes.first?.kind == .modified)
        #expect(changes.first?.previous?.version == "13.0")
    }

    @Test
    func identityIsScopedToSurface() {
        let changes = InventoryDiffer.diff(
            previous: [Fixture.item(surface: .homebrew, name: "x")],
            current: [Fixture.item(surface: .claudeConfig, name: "x")]
        )
        // Same name on different surfaces are different items: one removed, one added.
        #expect(changes.count == 2)
    }

    @Test
    func coexistingPackageVersionsReorderedAreNotAChange() {
        // A dependency tree legitimately holds the same package at two versions at once. A
        // lockfile parser iterates a dictionary, so it can emit them in a different order
        // between scans. That reordering must not read as a change on a stable system.
        let lockfile = "/proj/pnpm-lock.yaml"
        let older = Fixture.item(
            surface: .javascriptPackages, name: "zod", version: "3.25.76", path: lockfile, origin: "pnpm"
        )
        let newer = Fixture.item(
            surface: .javascriptPackages, name: "zod", version: "4.4.3", path: lockfile, origin: "pnpm"
        )

        let changes = InventoryDiffer.diff(previous: [older, newer], current: [newer, older])

        #expect(changes.isEmpty)
    }

    @Test
    func addingACoexistingPackageVersionIsAnAddition() {
        let lockfile = "/proj/pnpm-lock.yaml"
        let older = Fixture.item(
            surface: .javascriptPackages, name: "zod", version: "3.25.76", path: lockfile, origin: "pnpm"
        )
        let newer = Fixture.item(
            surface: .javascriptPackages, name: "zod", version: "4.4.3", path: lockfile, origin: "pnpm"
        )

        let changes = InventoryDiffer.diff(previous: [older], current: [older, newer])

        #expect(changes.count == 1)
        #expect(changes.first?.kind == .added)
        #expect(changes.first?.item.version == "4.4.3")
    }
}
