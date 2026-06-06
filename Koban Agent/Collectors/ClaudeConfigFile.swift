import Foundation

/// The subset of `~/.claude.json` Koban reads: MCP servers at user scope and nested under each
/// project. All keys are optional so the (large, evolving) file decodes even as it grows.
struct ClaudeConfigFile: Decodable {
    struct Project: Decodable {
        var mcpServers: [String: MCPServerSpec]?
    }

    var mcpServers: [String: MCPServerSpec]?
    var projects: [String: Project]?
}
