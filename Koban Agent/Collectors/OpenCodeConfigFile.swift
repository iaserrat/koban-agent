import Foundation

/// Decodable subset of OpenCode configuration Koban inventories locally.
struct OpenCodeConfigFile: Decodable {
    var mcp: [String: MCPServerSpec]?
    var plugin: [String]?
}
