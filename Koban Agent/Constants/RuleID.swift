import Foundation

// MARK: - RuleID

/// Stable identifiers for heuristic rules, used in findings and persistence.
enum RuleID {
    static let agentNewMCPServer = "agent.mcp.new-server"
    static let agentEphemeralRunner = "agent.config.ephemeral-runner"
    static let agentSuspiciousCommand = "agent.config.suspicious-command"
    static let agentRemoteTransport = "agent.config.remote-transport"
    static let agentDynamicAuthHelper = "agent.mcp.dynamic-auth-helper"
    static let agentNewHook = "agent.config.new-hook"
    static let agentNewSkill = "agent.config.new-skill"
    static let agentNewPlugin = "agent.config.new-plugin"
    static let agentNewCommand = "agent.config.new-command"
    static let agentNewRule = "agent.config.new-rule"
    static let agentNewInstruction = "agent.config.new-instruction"
    static let agentNewSettings = "agent.config.new-settings"
    static let packagesNewJavaScriptPackage = "packages.new-javascript-package"
    static let packagesNewPythonPackage = "packages.new-python-package"
    static let homebrewUntrustedTap = "homebrew.untrusted-tap"
    static let homebrewUnrequestedInstall = "homebrew.unrequested-install"
}
