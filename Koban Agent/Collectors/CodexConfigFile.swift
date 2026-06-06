import Foundation

/// Decodable subset of Codex TOML configuration Koban inventories locally.
struct CodexConfigFile: Decodable {
    var mcpServers: [String: MCPServerSpec]?

    private enum CodingKeys: String, CodingKey {
        case mcpServers = "mcp_servers"
    }
}
