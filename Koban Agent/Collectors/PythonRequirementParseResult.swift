import Foundation

struct PythonRequirementParseResult {
    var records: [PackageInventoryRecord] = []
    var issues: [CollectorIssue] = []

    mutating func append(_ result: Self) {
        records.append(contentsOf: result.records)
        issues.append(contentsOf: result.issues)
    }
}
