import Foundation

/// One MCP server entry as it appears in `~/.claude.json`. Decoded leniently: every field is
/// optional because stdio servers carry a `command`/`args` while remote servers carry a `url`.
struct MCPServerSpec: Decodable {
    var command: String?
    var args: [String]?
    var type: String?
    var url: String?
    var headersHelper: String?

    init(
        command: String? = nil,
        args: [String]? = nil,
        type: String? = nil,
        url: String? = nil,
        headersHelper: String? = nil
    ) {
        self.command = command
        self.args = args
        self.type = type
        self.url = url
        self.headersHelper = headersHelper
    }

    /// The detail string heuristics inspect: the transport URL for remote servers, otherwise
    /// the full command line. `nil` when the entry has neither (nothing to inventory).
    var detail: String? {
        var parts: [String] = []
        if let url, url.isEmpty == false {
            parts.append(url)
        } else if let command, command.isEmpty == false {
            parts.append(([command] + (args ?? [])).joined(separator: " "))
        }
        if headersHelper?.isEmpty == false {
            parts.append(HeuristicConstants.dynamicAuthHelperToken)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    /// The short origin label: the command for stdio servers, the URL for remote ones.
    var origin: String? {
        if let url, url.isEmpty == false {
            return url
        }
        return command
    }
}
