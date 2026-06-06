import Foundation

/// Dependency metadata filenames and globs Koban can discover.
enum PackageMetadataNames {
    static let packageLockName = "package-lock.json"
    static let npmShrinkwrapName = "npm-shrinkwrap.json"
    static let pnpmLockName = "pnpm-lock.yaml"
    static let yarnLockName = "yarn.lock"
    static let bunLockName = "bun.lock"
    static let uvLockName = "uv.lock"
    static let pyprojectName = "pyproject.toml"
    static let pylockName = "pylock.toml"

    static let javascriptLockfiles = [
        packageLockName,
        npmShrinkwrapName,
        pnpmLockName,
        yarnLockName,
        bunLockName
    ]

    static let pythonRequirementGlobs = [
        "requirements*.txt",
        "constraints*.txt"
    ]

    static let npmManager = "npm"
    static let pnpmManager = "pnpm"
    static let yarnManager = "yarn"
    static let bunManager = "bun"
    static let uvManager = "uv"
    static let pipManager = "pip"
    static let pyprojectManager = "pyproject"
    static let pylockManager = "pylock"
    static let packagePathPrefix = "node_modules/"
    static let npmPackagesKey = "packages"
    static let pnpmVersionSeparator = "@"
    static let yarnNPMProtocol = "@npm:"
    static let yarnVersionPrefix = "version "
    static let pythonConstraintsPrefix = "constraints"
    static let pythonCommentPrefix = "#"
    static let pythonOptionPrefix = "-"
    static let pythonEditablePrefix = "-e "
    static let pythonRequirementIncludePrefix = "-r "
    static let pythonLongRequirementIncludePrefix = "--requirement "
    static let pythonConstraintIncludePrefix = "-c "
    static let pythonLongConstraintIncludePrefix = "--constraint "
    static let pythonDirectReferenceSeparator = " @ "
    static let pythonVersionCharacters = "<>=!~"
    static let pythonLineContinuationSuffix = "\\"
    static let pythonHashOptionPrefix = "--hash="
    static let detailSeparator = " "
    static let resolvedDetailKey = "resolved"
    static let integrityDetailKey = "integrity"
    static let scopeDetailKey = "scope"
    static let devScope = "dev"
    static let optionalScope = "optional"
}
