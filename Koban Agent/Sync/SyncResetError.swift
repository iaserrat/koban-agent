/// Why a sync-identity reset could not complete cleanly. Carries a user-facing description (via
/// `String(describing:)`) so the Settings pane shows copy from the Constants layer rather than a
/// raw Swift error.
enum SyncResetError: Error, CustomStringConvertible {
    /// Sync expects enrollment (enabled, with a token and endpoint) but re-bootstrapping could not
    /// re-establish it, so the device is left unenrolled. Surfaced instead of a false success.
    case reenrollmentFailed
    /// Another configuration reload was already applying, so the reset was not run. Surfaced rather
    /// than dropped silently, since a reset is a deliberate user action, not a coalescible push.
    case reloadInProgress

    var description: String {
        switch self {
        case .reenrollmentFailed: SyncResetLabels.reenrollmentFailedMessage
        case .reloadInProgress: SyncResetLabels.reloadInProgressMessage
        }
    }
}
