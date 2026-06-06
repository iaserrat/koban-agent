import Foundation

struct ScanCommit {
    let surface: MonitoredSurface
    let previous: [InventoryItem]
    let current: [InventoryItem]
    let events: [ChangeEvent]
    let findings: [Finding]
    let presentFindings: [Finding]
    let issues: [CollectorIssue]
    let durationMilliseconds: Double
    let completedAt: Date

    init(
        surface: MonitoredSurface,
        previous: [InventoryItem],
        current: [InventoryItem],
        events: [ChangeEvent],
        findings: [Finding],
        presentFindings: [Finding] = [],
        issues: [CollectorIssue] = [],
        durationMilliseconds: Double,
        completedAt: Date
    ) {
        self.surface = surface
        self.previous = previous
        self.current = current
        self.events = events
        self.findings = findings
        self.presentFindings = presentFindings
        self.issues = issues
        self.durationMilliseconds = durationMilliseconds
        self.completedAt = completedAt
    }
}
