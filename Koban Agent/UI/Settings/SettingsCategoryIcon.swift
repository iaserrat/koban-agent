import Foundation

/// The leading glyph a Settings category shows in the sidebar. Ecosystems reuse their two-letter
/// monogram chip (the brand's stand-in for mismatched service logos); the pipeline sections and the
/// ruleset carry an SF Symbol instead, since they have no ecosystem identity.
enum SettingsCategoryIcon {
    case symbol(String)
    case surface(MonitoredSurface)
}
