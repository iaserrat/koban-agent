import Testing
@testable import Koban_Agent

struct MCPServerSpecTests {
    @Test
    func stdioServerExposesCommandLine() {
        let spec = MCPServerSpec(command: "npx", args: ["-y", "weather"], type: "stdio", url: nil)
        #expect(spec.origin == "npx")
        #expect(spec.detail == "npx -y weather")
    }

    @Test
    func remoteServerExposesURL() {
        let spec = MCPServerSpec(command: nil, args: nil, type: "http", url: "https://mcp.example.com")
        #expect(spec.origin == "https://mcp.example.com")
        #expect(spec.detail == "https://mcp.example.com")
    }

    @Test
    func emptyServerHasNoDetail() {
        let spec = MCPServerSpec(command: nil, args: nil, type: nil, url: nil)
        #expect(spec.detail == nil)
        #expect(spec.origin == nil)
    }

    @Test
    func dynamicAuthHelperIsRecordedWithoutCommandValue() {
        let spec = MCPServerSpec(
            url: "https://mcp.example.com",
            headersHelper: "security find-generic-password"
        )
        #expect(spec.origin == "https://mcp.example.com")
        #expect(spec.detail == "https://mcp.example.com headersHelper")
    }
}
