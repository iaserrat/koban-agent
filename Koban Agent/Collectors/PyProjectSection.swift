import Foundation

/// Python project metadata that declares dependencies.
struct PyProjectSection: Decodable {
    var dependencies: [String]?
    var optionalDependencies: [String: [String]]?

    private enum CodingKeys: String, CodingKey {
        case dependencies
        case optionalDependencies = "optional-dependencies"
    }
}
