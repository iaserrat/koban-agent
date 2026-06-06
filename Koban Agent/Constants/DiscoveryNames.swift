import Foundation

/// File and directory names used by project and home signal discovery.
enum DiscoveryNames {
    static let homeRoot = "~"

    static let defaultProjectRoots = ["~/src", "~/Code", "~/Developer", "~/Projects"]

    static let defaultExcludeDirectories = [
        ".git",
        "node_modules",
        ".venv",
        "venv",
        "__pycache__",
        ".tox",
        ".mypy_cache",
        ".pytest_cache",
        "dist",
        "build",
        ".next",
        ".turbo",
        ".cache"
    ]

    static let homeSignalFileNames = [
        "AGENTS.md",
        "CLAUDE.md",
        "CLAUDE.local.md",
        ".mcp.json",
        ".cursorrules",
        "opencode.json",
        "opencode.jsonc",
        "package-lock.json",
        "npm-shrinkwrap.json",
        "pnpm-lock.yaml",
        "yarn.lock",
        "bun.lock",
        "uv.lock",
        "pyproject.toml",
        "pylock.toml"
    ]

    static let homeSignalFileGlobs = [
        "requirements*.txt",
        "constraints*.txt",
        "*.rules",
        "*.mdc"
    ]

    static let protectedUserDirectories = [
        "Library",
        "Applications",
        "Movies",
        "Music",
        "Pictures",
        "Public",
        "Desktop",
        "Documents",
        "Downloads"
    ]
}
