import Foundation

/// Decodable subset of npm lockfiles.
struct NpmLockfile: Decodable {
    var packages: [String: NpmPackage]?
}
