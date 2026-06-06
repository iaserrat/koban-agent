import Foundation

/// SF Symbol names for app chrome that isn't tied to a model type. Surface/severity/change
/// symbols live on their respective types; these are the menu-bar shell's own.
enum Symbols {
    static let shield = "shield.lefthalf.filled"
    static let allClear = "checkmark.shield"
    static let quit = "power"
    static let checkForUpdates = "arrow.triangle.2.circlepath"

    /// Extended-window chrome.
    static let window = "macwindow"
    static let overview = "square.grid.2x2"
    static let findings = "exclamationmark.shield"
    static let activity = "list.bullet.rectangle"
    static let path = "folder"
    static let detail = "terminal"
    static let matched = "scope"
    static let search = "magnifyingglass"
    static let clearFilter = "xmark.circle.fill"

    /// The generic inventory glyph, used where a surface no longer carries its own icon (e.g. an
    /// empty selection state). Ecosystems are identified by their monogram chip, not a symbol.
    static let inventory = "shippingbox"

    /// First-run onboarding: the three trust promises and the per-surface "indexed" check. Each
    /// promise glyph reads the claim it sits beside (privacy, no scary entitlements, report-only).
    static let promisePrivacy = "eye.slash"
    static let promiseNoEntitlement = "lock.shield"
    static let promiseReportsOnly = "binoculars"
    static let indexed = "checkmark"
    static let onboardingDone = "checkmark.circle.fill"
    static let chevronBack = "chevron.left"

    /// Settings page: the toolbar gear, list add/remove, the rule add/delete, and the conflict
    /// banner's warning glyph.
    static let settings = "gearshape"
    static let addItem = "plus.circle"
    static let removeItem = "minus.circle"
    static let addRule = "plus"
    static let deleteRule = "trash"
    static let warning = "exclamationmark.triangle.fill"
}
