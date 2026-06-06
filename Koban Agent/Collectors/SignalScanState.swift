import Foundation

/// Mutable counters for one bounded signal discovery pass.
struct SignalScanState {
    let startedAt: Date
    var candidates: [URL] = []
    var issues: [CollectorIssue] = []
    var directoriesVisited = 0
    var filesVisited = 0
    private(set) var isExhausted = false

    mutating func markExhausted() {
        isExhausted = true
    }
}
