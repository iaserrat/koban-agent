import Foundation
import Testing
@testable import Koban_Agent

struct SyncStatusTests {
    @Test
    func disabledReadsAsOff() {
        #expect(SyncStatus.disabled.phase == .off)
    }

    @Test
    func enabledWithNothingQueuedAndNeverDrainedReadsAsNeverSynced() {
        let status = SyncStatus(isEnabled: true, pendingCount: 0, failedCount: 0, lastSyncedAt: nil)
        #expect(status.phase == .neverSynced)
    }

    @Test
    func pendingEventsReadAsSyncing() {
        let status = SyncStatus(isEnabled: true, pendingCount: 4, failedCount: 0, lastSyncedAt: nil)
        #expect(status.phase == .syncing)
    }

    @Test
    func poisonedEventsOutrankPendingAsFailing() {
        let status = SyncStatus(isEnabled: true, pendingCount: 4, failedCount: 2, lastSyncedAt: nil)
        #expect(status.phase == .failing)
    }

    @Test
    func drainedOutboxReadsAsUpToDate() {
        let status = SyncStatus(
            isEnabled: true,
            pendingCount: 0,
            failedCount: 0,
            lastSyncedAt: Date(timeIntervalSince1970: 1000)
        )
        #expect(status.phase == .upToDate)
    }
}
