import SwiftUI

/// Layout design tokens. Every spacing, size, and width the UI uses lives here as a named
/// value - the views never embed a bare number (see CLAUDE.md).
enum Metrics {
    static let popoverWidth: CGFloat = 400

    static let spacingTight: CGFloat = 4
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16

    static let iconWidth: CGFloat = 22
    static let statusDotSize: CGFloat = 8

    /// How many rows each section shows in the glance panel before "See more" takes over.
    /// The window shows everything; the panel stays a short summary (see CLAUDE.md UX bar).
    static let maxFindingRows = 3
    static let maxActivityRows = 3
    static let rationaleLineLimit = 2

    /// Interactive row chrome: the hover/selection highlight inset and corner.
    static let rowInsetH: CGFloat = 8
    static let rowInsetV: CGFloat = 6
    static let rowCornerRadius: CGFloat = 6
    static let hoverFadeSeconds = 0.12

    /// Grouped panel chrome: corner, inner padding, and the hairline borders that carry depth
    /// instead of shadows (the brand's flat-elevation rule).
    static let panelCornerRadius: CGFloat = 10
    static let panelPadding: CGFloat = 6
    static let hairline: CGFloat = 1

    /// Section-label tracking, in points. The brand sets label caps at 0.06em; at the caption2
    /// size that lands near here.
    static let labelTracking: CGFloat = 0.6

    /// Negative tracking for size-led headings, the Cursor move: large type carries hierarchy at
    /// a regular/medium weight with letters drawn slightly tighter, instead of going bold.
    static let headingTracking: CGFloat = -0.4

    /// The ecosystem monogram chip: a small rounded square holding a two-letter mark, plus the
    /// bordered "file chips" that present paths, commands, and matched evidence in detail panes.
    static let monogramSize: CGFloat = 22
    static let monogramFontSize: CGFloat = 11
    static let chipCornerRadius: CGFloat = 6
    static let chipPaddingH: CGFloat = 8
    static let chipPaddingV: CGFloat = 5

    /// Inner line spacing two-line rows use (a finding/inventory row's title over its subtitle).
    static let rowLineSpacing: CGFloat = 3

    /// The monitor window's stream table: the row and header heights, the fixed column widths (the
    /// `context` column is flexible and takes the rest), and the trailing severity-flag column.
    static let streamRowHeight: CGFloat = 30
    static let streamHeaderHeight: CGFloat = 30
    static let streamTimeWidth: CGFloat = 92
    static let streamEventWidth: CGFloat = 150
    static let streamSurfaceWidth: CGFloat = 132
    static let streamDetailWidth: CGFloat = 170
    static let streamVersionWidth: CGFloat = 96
    static let streamOriginWidth: CGFloat = 150
    static let streamSeverityWidth: CGFloat = 100
    static let streamFlagWidth: CGFloat = 26
    /// The accent bar drawn down the leading edge of the selected stream row.
    static let streamSelectionBarWidth: CGFloat = 2

    /// The monitor window's right-hand by-surface bars and its bottom detail panel: the aside's
    /// width, a bar's track height and corner, and the two panes' minimum heights in the split.
    static let surfaceAsideWidth: CGFloat = 248
    static let surfaceBarHeight: CGFloat = 7
    static let surfaceBarCornerRadius: CGFloat = 4
    static let detailPanelMinHeight: CGFloat = 220
    static let streamMinHeight: CGFloat = 240
    static let severityDotSize: CGFloat = 7

    /// The monitor toolbar and its segmented scope control: the bar's height, the search field's
    /// width, and the segment's inset, padding, and group corner.
    static let toolbarHeight: CGFloat = 48
    static let toolbarSearchWidth: CGFloat = 240
    static let segmentInset: CGFloat = 3
    static let segmentPaddingH: CGFloat = 11
    static let segmentPaddingV: CGFloat = 4
    static let segmentGroupCornerRadius: CGFloat = 8
    static let windowMinWidth: CGFloat = 880
    static let windowMinHeight: CGFloat = 560
    static let brandMarkSize: CGFloat = 20

    /// The brand mark drawn at the leading edge of the popover header (no chip behind it).
    static let headerMarkSize: CGFloat = 22

    /// The live indicator: the status dot's soft surrounding glow and its slow "breathing" cycle
    /// (suppressed under Reduce Motion). The glow is a blurred disc behind the dot.
    static let liveGlowSize: CGFloat = 16
    static let liveGlowBlur: CGFloat = 3
    static let liveGlowDimOpacity = 0.35
    static let livePulseSeconds = 1.8

    /// The "xN" occurrence badge.
    static let badgePaddingH: CGFloat = 6
    static let badgePaddingV: CGFloat = 2

    /// The extended window's default opening size: it opens the stream, its surface bars, and the
    /// detail panel above their minimums with slack, so the window lands on its intended proportions
    /// rather than pinned to `windowMinWidth`/`windowMinHeight`.
    static let windowDefaultWidth: CGFloat = 1140
    static let windowDefaultHeight: CGFloat = 720

    /// Width of the leading column (labels) in the finding/inventory detail panes.
    static let detailLabelWidth: CGFloat = 130

    /// The first-run onboarding window: a fixed, centred card (not resizable), and the chrome the
    /// three steps share. The window is the one moment Koban asks for full attention, so it is
    /// roomier than the popover but still a single focused surface.
    static let onboardingWindowWidth: CGFloat = 480
    static let onboardingWindowHeight: CGFloat = 600
    static let onboardingContentPadding: CGFloat = 30
    static let onboardingHeroMarkSize: CGFloat = 52
    static let onboardingHeadlineSpacing: CGFloat = 12
    static let onboardingSectionSpacing: CGFloat = 22
    static let onboardingItemSpacing: CGFloat = 14
    /// The primary CTA: height, corner, and the white wash laid over the accent fill on hover.
    static let onboardingButtonHeight: CGFloat = 40
    static let onboardingButtonCornerRadius: CGFloat = 9
    static let onboardingButtonHoverOpacity = 0.1
    /// The step-progress dots at the foot of the welcome and surfaces steps. The current step's dot
    /// stretches into a short capsule so position reads at a glance.
    static let onboardingStepDotSize: CGFloat = 6
    static let onboardingStepDotActiveWidth: CGFloat = 16
    /// The grid of watched surfaces: column count and a chip's row height.
    static let onboardingSurfaceColumns = 2
    static let onboardingSurfaceRowHeight: CGFloat = 34
    /// The indexing step: the slim determinate progress bar and a surface row's fixed height.
    static let onboardingProgressBarHeight: CGFloat = 5
    static let onboardingIndexRowHeight: CGFloat = 38

    /// First-run motion: the step crossfade-and-slide, the per-row entrance stagger, and the
    /// completion reveal. Eased out, suppressed under Reduce Motion (see the step views).
    static let onboardingTransitionSeconds = 0.4
    static let onboardingStaggerSeconds = 0.05
    static let onboardingRevealSeconds = 0.55
    /// How far a step slides as it crosses, and how far a row rises as it enters.
    static let onboardingStepSlide: CGFloat = 24
    static let onboardingRowRise: CGFloat = 8

    /// The Settings page: the category sidebar's width, the leading label column in a field row,
    /// a number field's width, and the vertical rhythm between rows and between sections.
    static let settingsSidebarWidth: CGFloat = 200
    static let settingsLabelWidth: CGFloat = 220
    static let settingsNumberFieldWidth: CGFloat = 130
    static let settingsContentPadding: CGFloat = 20
    static let settingsRowSpacing: CGFloat = 12
    static let settingsSectionSpacing: CGFloat = 24
    /// The string-list editor's add/remove row chrome.
    static let settingsListRowSpacing: CGFloat = 6
    /// The rule editor sheet's fixed size, and a rule list row's inner padding.
    static let settingsSheetWidth: CGFloat = 560
    static let settingsSheetHeight: CGFloat = 640
    static let settingsRulePadding: CGFloat = 10
    /// The rule editor's rationale field grows between these line counts before scrolling.
    static let settingsRationaleMinLines = 2
    static let settingsRationaleMaxLines = 5
}
