import Foundation
import Testing
@testable import Koban_Agent

// MARK: - SurfaceScanSchedulerPendingOperationTests

struct SurfaceScanSchedulerPendingOperationTests {
    @Test
    func pendingScanUsesLatestOperation() async {
        let scheduler = SurfaceScanScheduler()
        let probe = LabeledScanProbe()

        await scheduler.schedule(.homebrew) {
            await probe.run(label: ScanOperationLabels.startup)
        }
        await probe.waitForStartedLabels([ScanOperationLabels.startup])

        await scheduler.schedule(.homebrew) {
            await probe.run(label: ScanOperationLabels.rescan)
        }

        await probe.finishNext()
        await probe.waitForStartedLabels([ScanOperationLabels.startup, ScanOperationLabels.rescan])
        await probe.finishNext()

        let labels = await probe.startedLabels
        #expect(labels == [ScanOperationLabels.startup, ScanOperationLabels.rescan])
    }
}

// MARK: - ScanOperationLabels

private enum ScanOperationLabels {
    static let startup = "startup"
    static let rescan = "rescan"
}

// MARK: - LabeledScanProbe

private actor LabeledScanProbe {
    private(set) var startedLabels: [String] = []
    private var finishContinuations: [CheckedContinuation<Void, Never>] = []
    private var startWaiters: [([String], CheckedContinuation<Void, Never>)] = []

    func run(label: String) async {
        startedLabels.append(label)
        resumeSatisfiedStartWaiters()
        await withCheckedContinuation { continuation in
            finishContinuations.append(continuation)
        }
    }

    func waitForStartedLabels(_ labels: [String]) async {
        guard startedLabels == labels else {
            await withCheckedContinuation { continuation in
                startWaiters.append((labels, continuation))
            }
            return
        }
    }

    func finishNext() {
        guard finishContinuations.isEmpty == false else { return }
        finishContinuations.removeFirst().resume()
    }

    private func resumeSatisfiedStartWaiters() {
        let ready = startWaiters.filter { startedLabels == $0.0 }
        startWaiters.removeAll { startedLabels == $0.0 }
        for waiter in ready {
            waiter.1.resume()
        }
    }
}
