import Foundation

// MARK: - SyncStatus

/// A glanceable summary of the sensor's upload state, surfaced on the home dashboard beside the
/// version. Sync is off until an operator configures a backend; when on, it reports how far the
/// outbox is behind and when it last drained, so the dashboard can answer "is my data reaching the
/// fleet?" without opening Settings.
struct SyncStatus: Hashable {
    /// Whether a sync backend is configured and uploading is enabled.
    var isEnabled: Bool
    /// Events queued but not yet acknowledged by the backend (pending plus in-flight).
    var pendingCount: Int
    /// Events the backend rejected past retry (poisoned); these need operator attention.
    var failedCount: Int
    /// When the outbox last drained successfully, or `nil` if it never has.
    var lastSyncedAt: Date?

    /// The resting state: sync turned off.
    static let disabled = Self(isEnabled: false, pendingCount: 0, failedCount: 0, lastSyncedAt: nil)
}

extension SyncStatus {
    /// The single state the glance renders, resolved by priority so one phase wins: a stuck upload
    /// is the most important signal, then an in-progress drain, then the calm "up to date".
    enum Phase: Equatable {
        case off
        case failing
        case syncing
        case neverSynced
        case upToDate
    }

    var phase: Phase {
        guard isEnabled else { return .off }
        if failedCount > 0 { return .failing }
        if pendingCount > 0 { return .syncing }
        if lastSyncedAt == nil { return .neverSynced }
        return .upToDate
    }
}
