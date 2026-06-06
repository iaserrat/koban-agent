import Foundation
import Testing
@testable import Koban_Agent

struct AgentConfigInventoryMapperTests {
    @Test
    func mapsNormalizedAgentConfigToInventory() {
        let item = AgentConfigItem(
            surface: .codexConfig,
            kind: .hook,
            name: "before_run",
            version: "1",
            path: "/tmp/hooks.json",
            origin: "codex-hooks",
            detail: "detail"
        )

        let inventoryItem = AgentConfigInventoryMapper.inventoryItem(from: item)

        #expect(inventoryItem.surface == .codexConfig)
        #expect(inventoryItem.kind == .hook)
        #expect(inventoryItem.name == "before_run")
        #expect(inventoryItem.version == "1")
        #expect(inventoryItem.path == "/tmp/hooks.json")
        #expect(inventoryItem.provenance.origin == "codex-hooks")
        #expect(inventoryItem.provenance.detail == "detail")
    }
}
