import Foundation

/// Asset-catalog image names for custom (non-SF-Symbol) artwork. SF Symbol names live in
/// `Symbols`; these are images shipped in `Assets.xcassets`.
enum ImageAssets {
    /// The Koban shield mark. A template-rendered vector PDF, so it tints to the current
    /// foreground/appearance. Used for the menu-bar status item and the in-app brand spots via
    /// `BrandMark`.
    static let brandMark = "KobanMark"
}
