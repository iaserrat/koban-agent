import Foundation

/// File and directory match lists for opt-in home signal discovery.
struct HomeSignalNames: Hashable {
    var files: [String]
    var globs: [String]
    var prunes: [String]
}
