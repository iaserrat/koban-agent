import Foundation

struct PythonRequirementParseContext {
    let root: URL
    let validator: PackageMetadataFileValidator
    let budget: PythonRequirementParseBudget
    var state = PythonRequirementParseState()
}
