import Testing
@testable import Koban_Agent

struct MCPInventoryMapperTests {
    @Test
    func mapsRemoteMCPServerWithoutSecretFields() {
        let spec = MCPServerSpec(
            url: "https://mcp.example.com",
            headersHelper: "security find-generic-password"
        )

        let item = MCPInventoryMapper.agentConfigItem(
            surface: .cursorConfig,
            name: "gateway",
            path: "/tmp/mcp.json",
            spec: spec
        )

        #expect(item?.surface == .cursorConfig)
        #expect(item?.kind == .mcpServer)
        #expect(item?.name == "gateway")
        #expect(item?.path == "/tmp/mcp.json")
        #expect(item?.origin == "https://mcp.example.com")
        #expect(item?.detail == "https://mcp.example.com headersHelper")
    }

    @Test
    func skipsMCPServerWithoutOrigin() {
        let item = MCPInventoryMapper.agentConfigItem(
            surface: .claudeConfig,
            name: "empty",
            path: "/tmp/mcp.json",
            spec: MCPServerSpec()
        )

        #expect(item == nil)
    }
}
