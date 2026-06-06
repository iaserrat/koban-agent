import Foundation

/// Decodable package entry in Python lockfiles.
struct PythonLockedPackage: Decodable {
    var name: String
    var version: String?
}
