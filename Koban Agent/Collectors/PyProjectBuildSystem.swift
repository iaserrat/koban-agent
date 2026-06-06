import Foundation

/// Python build-system requirements from `pyproject.toml`.
struct PyProjectBuildSystem: Decodable {
    var requires: [String]?
}
