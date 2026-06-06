import Foundation

struct ClaudeExpansionFixtureURLs {
    let userConfigURL: URL
    let projectConfigURL: URL
    let settingsURL: URL
    let commandDirectoryURL: URL
    let skillDirectoryURL: URL
    let instructionURL: URL

    init(directory: URL) {
        userConfigURL = directory.appending(component: ".claude.json")
        projectConfigURL = directory.appending(path: "repo/.mcp.json")
        settingsURL = directory.appending(path: "repo/.claude/settings.json")
        commandDirectoryURL = directory.appending(path: "repo/.claude/commands")
        skillDirectoryURL = directory.appending(path: "repo/.claude/skills/audit")
        instructionURL = directory.appending(path: "repo/CLAUDE.md")
    }
}
