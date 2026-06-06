import Combine
import Observation
import Sparkle

/// Owns Sparkle's updater and exposes the one bit of state the menu-bar footer needs: whether a
/// manual "Check for Updates" is currently allowed. Sparkle handles everything else (scheduled
/// background checks, download, signature verification, install) through its standard user driver,
/// so this is a thin adapter at the update IO edge, not logic of our own.
///
/// The feed URL and EdDSA public key live in `Info.plist` (`SUFeedURL`, `SUPublicEDKey`), which is
/// where Sparkle reads them; they are deployment configuration, not in-code literals.
@MainActor
@Observable
final class UpdaterModel {
    /// Mirrors `SPUUpdater.canCheckForUpdates`, so the footer row can disable itself while a check
    /// is already in flight. Driven by Sparkle via the KVO publisher below.
    private(set) var canCheckForUpdates = false

    @ObservationIgnored private let controller: SPUStandardUpdaterController
    @ObservationIgnored private var cancellable: AnyCancellable?

    init() {
        // `startingUpdater: true` schedules Sparkle's background checks immediately. As a menu-bar
        // agent we have no main menu, so the standard user driver is the whole update UI surface.
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        cancellable = controller.updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] canCheck in self?.canCheckForUpdates = canCheck }
    }

    /// Runs a user-initiated update check, showing Sparkle's standard progress and prompt UI.
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
