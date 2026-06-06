import Foundation

/// Human-facing origin labels for Homebrew inventory items. Kept here so no label string is
/// embedded in collector logic (see CLAUDE.md).
enum HomebrewLabels {
    /// Origin used when Homebrew has no readable receipt. Unknown provenance must remain
    /// unknown rather than being treated as a trusted tap.
    static let unknownTap = "unknown"

    /// Joins multiple installed version directories into one version string.
    static let versionSeparator = ", "
}
