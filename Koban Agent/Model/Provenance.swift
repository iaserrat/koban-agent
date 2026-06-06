import Foundation

/// Where an inventory item came from, reconstructed from a package manager's own
/// on-disk metadata. FSEvents gives us no process attribution, so this is our best
/// available "who put this here".
struct Provenance: Codable, Hashable {
    /// Short, human-facing origin label: a Homebrew tap, "cask", or an MCP command name.
    var origin: String

    /// For Homebrew: whether the user asked for this explicitly vs. it being pulled in
    /// as a dependency. `nil` when the surface has no such concept.
    var installedOnRequest: Bool?

    /// The full detail heuristics inspect: an MCP command line or transport URL.
    /// Kept separate from `origin` so the UI stays terse while rules stay precise.
    var detail: String?

    init(origin: String, installedOnRequest: Bool? = nil, detail: String? = nil) {
        self.origin = origin
        self.installedOnRequest = installedOnRequest
        self.detail = detail
    }
}
