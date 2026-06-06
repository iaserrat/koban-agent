import Foundation

/// Decodable subset of uv lockfiles.
struct UvLockfile: Decodable {
    var package: [PythonLockedPackage]?
    var packages: [PythonLockedPackage]?
}
