import Testing
@testable import Koban_Agent

struct InventoryKindTests {
    @Test
    func itemIdentityIncludesKind() {
        let package = Fixture.item(kind: .package, name: "example")
        let hook = Fixture.item(kind: .hook, name: "example")

        #expect(package.id != hook.id)
    }

    @Test
    func v1SurfacesArePresent() {
        #expect(MonitoredSurface.allCases.contains(.codexConfig))
        #expect(MonitoredSurface.allCases.contains(.piConfig))
        #expect(MonitoredSurface.allCases.contains(.cursorConfig))
        #expect(MonitoredSurface.allCases.contains(.opencodeConfig))
        #expect(MonitoredSurface.allCases.contains(.javascriptPackages))
        #expect(MonitoredSurface.allCases.contains(.pythonPackages))
    }
}
