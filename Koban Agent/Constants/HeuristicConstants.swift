import Foundation

// MARK: - HeuristicConstants

/// Tokens and identifiers the heuristic rules match against. The single home for
/// rule literals; no rule may embed a bare string or number (see CLAUDE.md).
enum HeuristicConstants {
    static let codexConfigOrigin = "codex-config"
    static let codexHooksOrigin = "codex-hooks"
    static let codexRulesOrigin = "codex-rules"
    static let codexSkillsOrigin = "codex-skills"
    static let cursorMCPOrigin = "cursor-mcp"
    static let cursorRulesOrigin = "cursor-rules"
    static let cursorLegacyRulesOrigin = "cursor-legacy-rules"
    static let cursorInstructionOrigin = "cursor-instruction"
    static let openCodeConfigOrigin = "opencode-config"
    static let openCodeAgentOrigin = "opencode-agent"
    static let openCodeCommandOrigin = "opencode-command"
    static let openCodePluginOrigin = "opencode-plugin"
    static let openCodeInstructionOrigin = "opencode-instruction"
    static let piImportOrigin = "pi-import"
    static let piSettingsOrigin = "pi-settings"
    static let piPackageOrigin = "pi-package"
    /// Shell constructs that indicate an MCP server runs arbitrary downloaded code.
    static let suspiciousCommandTokens: [String] = [
        "curl", "wget", "| sh", "| bash", "bash -c", "sh -c", "eval", "base64"
    ]

    /// On-the-fly package runners: they execute code fetched at launch time.
    static let ephemeralRunnerCommands: [String] = ["npx", "uvx", "bunx", "pnpm dlx"]

    /// URL schemes that mean an MCP server talks to a remote endpoint rather than stdio.
    static let remoteTransportSchemes: [String] = ["http", "https", "ws", "wss"]
    static let urlSchemeSeparator = "://"

    /// MCP field that runs a command to generate dynamic auth headers.
    static let dynamicAuthHelperToken = "headersHelper"

    /// Homebrew taps shipped and trusted by default. Anything else is third-party.
    static let trustedHomebrewTaps: [String] = ["homebrew/core", "homebrew/cask"]

    /// Agent configuration surfaces that share behavior-affecting rule defaults.
    static let agentConfigSurfaces: [MonitoredSurface] = [
        .claudeConfig,
        .codexConfig,
        .piConfig,
        .cursorConfig,
        .opencodeConfig
    ]
}
