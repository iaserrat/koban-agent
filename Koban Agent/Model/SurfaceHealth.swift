import Foundation

struct SurfaceHealth: Codable, Hashable, Identifiable {
    var surface: MonitoredSurface
    var state: SurfaceHealthState
    var lastScanStartedAt: Date?
    var lastScanCompletedAt: Date?
    var lastSuccessfulScanAt: Date?
    var lastFailure: String?
    var lastWatchIssue: String?
    var lastWatchIssueAt: Date?
    var lastScanDurationMilliseconds: Double?
    var itemCount: Int
    var lastScanEventCount: Int
    var lastScanFindingCount: Int
    var lastScanIssueCount: Int
    var lastScanAddedItemCount: Int
    var lastScanModifiedItemCount: Int
    var lastScanRemovedItemCount: Int
    var watchPathCount: Int

    var id: MonitoredSurface {
        surface
    }

    init(
        surface: MonitoredSurface,
        state: SurfaceHealthState = .idle,
        lastScanStartedAt: Date? = nil,
        lastScanCompletedAt: Date? = nil,
        lastSuccessfulScanAt: Date? = nil,
        lastFailure: String? = nil,
        lastWatchIssue: String? = nil,
        lastWatchIssueAt: Date? = nil,
        lastScanDurationMilliseconds: Double? = nil,
        itemCount: Int = 0,
        lastScanEventCount: Int = 0,
        lastScanFindingCount: Int = 0,
        lastScanIssueCount: Int = 0,
        lastScanAddedItemCount: Int = 0,
        lastScanModifiedItemCount: Int = 0,
        lastScanRemovedItemCount: Int = 0,
        watchPathCount: Int = 0
    ) {
        self.surface = surface
        self.state = state
        self.lastScanStartedAt = lastScanStartedAt
        self.lastScanCompletedAt = lastScanCompletedAt
        self.lastSuccessfulScanAt = lastSuccessfulScanAt
        self.lastFailure = lastFailure
        self.lastWatchIssue = lastWatchIssue
        self.lastWatchIssueAt = lastWatchIssueAt
        self.lastScanDurationMilliseconds = lastScanDurationMilliseconds
        self.itemCount = itemCount
        self.lastScanEventCount = lastScanEventCount
        self.lastScanFindingCount = lastScanFindingCount
        self.lastScanIssueCount = lastScanIssueCount
        self.lastScanAddedItemCount = lastScanAddedItemCount
        self.lastScanModifiedItemCount = lastScanModifiedItemCount
        self.lastScanRemovedItemCount = lastScanRemovedItemCount
        self.watchPathCount = watchPathCount
    }

    var lastScanTelemetry: ScanTelemetry {
        ScanTelemetry(
            itemCount: itemCount,
            eventCount: lastScanEventCount,
            findingCount: lastScanFindingCount,
            addedItemCount: lastScanAddedItemCount,
            modifiedItemCount: lastScanModifiedItemCount,
            removedItemCount: lastScanRemovedItemCount
        )
    }

    mutating func recordSuccess(
        telemetry: ScanTelemetry,
        issues: [CollectorIssue] = [],
        durationMilliseconds: Double,
        at date: Date
    ) {
        state = issues.isEmpty ? .healthy : .degraded
        lastScanCompletedAt = date
        lastSuccessfulScanAt = date
        lastFailure = issues.isEmpty
            ? nil
            : HealthMessages.collectorVisibilityIssues(count: issues.count, firstIssue: issues.first)
        lastScanDurationMilliseconds = durationMilliseconds
        itemCount = telemetry.itemCount
        lastScanEventCount = telemetry.eventCount
        lastScanFindingCount = telemetry.findingCount
        lastScanIssueCount = issues.count
        lastScanAddedItemCount = telemetry.addedItemCount
        lastScanModifiedItemCount = telemetry.modifiedItemCount
        lastScanRemovedItemCount = telemetry.removedItemCount
    }
}
