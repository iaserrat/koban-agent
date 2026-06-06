import Foundation

/// Decodable package entry in an npm lockfile.
struct NpmPackage: Decodable {
    var version: String?
    var resolved: String?
    var integrity: String?
    var dev: Bool?
    var optional: Bool?
}
