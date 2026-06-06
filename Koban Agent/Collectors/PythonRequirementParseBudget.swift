import Foundation

struct PythonRequirementParseBudget {
    let maxIncludedFiles: Int
    let maxIncludeDepth: Int

    static let defaultValue = Self(
        maxIncludedFiles: ConfigurationDefaults.pythonRequirementMaxIncludedFiles,
        maxIncludeDepth: ConfigurationDefaults.pythonRequirementMaxIncludeDepth
    )
}
