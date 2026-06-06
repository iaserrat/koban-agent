import Foundation

/// Decodable subset of Pi MCP configuration Koban inventories locally.
struct PiConfigFile: Decodable {
    var mcpServers: [String: MCPServerSpec]?
    var imports: [String]?
}
