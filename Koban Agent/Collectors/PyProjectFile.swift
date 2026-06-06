import Foundation

/// Decodable subset of `pyproject.toml` dependency declarations.
struct PyProjectFile: Decodable {
    var project: PyProjectSection?
    var buildSystem: PyProjectBuildSystem?
    var dependencyGroups: [String: [String]]?

    private enum CodingKeys: String, CodingKey {
        case project
        case buildSystem = "build-system"
        case dependencyGroups = "dependency-groups"
    }
}
