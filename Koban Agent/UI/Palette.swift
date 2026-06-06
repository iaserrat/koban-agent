import SwiftUI

/// The Koban brand palette. These are the same design tokens the marketing site ships
/// (kobanhq.com DESIGN.md), so the agent and the website read as one product: cool graphite
/// neutrals (hue 230), a Fleet Violet accent (hue 285), and Finding Amber (hue 62) for findings.
///
/// The literal values live in `Assets.xcassets` as sRGB colour sets (converted from the brand's
/// OKLCH tokens, noted per role below); this enum is the single, typed home that names them. Koban
/// renders dark-mode only (see CLAUDE.md), so every role is one fixed colour, not a light/dark pair.
enum Palette {
    /// Graphite page base, the popover's backdrop and the window's content ground. oklch(0.21 0.006 230).
    static let bg = Color("KobanBg", bundle: .main)
    /// The deepest well: the window sidebar, recessed a step below the content. oklch(0.18 0.004 230).
    static let bgDeep = Color("KobanBgDeep", bundle: .main)
    /// Panel surface: grouped wells that sit one step above the base. oklch(0.27 0.008 230).
    static let surface = Color("KobanSurface", bundle: .main)
    /// Raised panel: small chips and badges a further step up. oklch(0.32 0.01 230).
    static let surfaceRaised = Color("KobanSurfaceRaised", bundle: .main)

    /// Primary ink: titles and primary copy. oklch(0.96 0.004 230).
    static let ink = Color("KobanInk", bundle: .main)
    /// Muted ink: secondary copy and inactive glyphs. oklch(0.76 0.008 230).
    static let inkMuted = Color("KobanInkMuted", bundle: .main)
    /// Subtle ink: captions, metadata, section labels. oklch(0.58 0.01 230).
    static let inkSubtle = Color("KobanInkSubtle", bundle: .main)

    /// Fleet Violet: the live state, primary action, and current selection. Sourced from the
    /// Koban mark, so it ties back to the logo rather than reading as a generic accent. This is
    /// the same asset the target's global accent colour points at, referenced by name so it
    /// resolves to the brand violet in every rendering context, not the system default.
    static let accent = Color("AccentColor", bundle: .main)
    /// A 12% violet wash for hover highlights and soft fills. accent @ 12%.
    static let accentSoft = Color("KobanAccentSoft", bundle: .main)

    /// Finding Amber: notable findings and attention states. Informative, never alarmist
    /// (see the brand's "warm amber, not screaming crimson"). oklch(0.72 0.09 62).
    static let alert = Color("KobanAlert", bundle: .main)
    /// A brighter amber for amber text that needs to stay legible on dark. oklch(0.82 0.07 62).
    static let alertInk = Color("KobanAlertInk", bundle: .main)
    /// Crimson reserved for the top severity and genuine degradation. A controlled red, tuned a
    /// step calmer than the system's. oklch(0.60 0.175 22).
    static let critical = Color("KobanCritical", bundle: .main)

    /// Hairline border for separators and grouped panels. ink @ 10%.
    static let border = Color("KobanBorder", bundle: .main)
    /// Stronger hairline for the panels that carry the most weight. ink @ 16%.
    static let borderStrong = Color("KobanBorderStrong", bundle: .main)
}
