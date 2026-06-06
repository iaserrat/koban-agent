// MARK: - IndexingProgress

/// Observes the first load: the engine's startup priming of every surface. The onboarding indexing
/// screen passes a live reporter so it can show which surface is being read and when the baseline
/// is complete; steady-state startups use `.silent`. Held as a value of `@Sendable` closures so it
/// crosses into the engine actor without coupling it to the UI.
struct IndexingProgress {
    /// The full set of surfaces about to be primed, in collector order, reported once up front.
    let willBegin: @Sendable ([MonitoredSurface]) async -> Void
    /// One surface is starting its baseline scan.
    let willIndex: @Sendable (MonitoredSurface) async -> Void
    /// One surface finished its baseline scan.
    let didIndex: @Sendable (MonitoredSurface) async -> Void
    /// Every surface has been primed.
    let didComplete: @Sendable () async -> Void

    /// The default: report nothing. Used for every startup after the first run.
    static let silent = Self(
        willBegin: { _ in },
        willIndex: { _ in },
        didIndex: { _ in },
        didComplete: {}
    )
}
