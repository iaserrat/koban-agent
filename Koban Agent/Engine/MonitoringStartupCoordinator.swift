// MARK: - MonitoringStartupCoordinator

struct MonitoringStartupCoordinator {
    let primer: MonitoringPrimer
    let scheduler: SurfaceScanScheduler
    let progress: IndexingProgress

    init(primer: MonitoringPrimer, scheduler: SurfaceScanScheduler, progress: IndexingProgress = .silent) {
        self.primer = primer
        self.scheduler = scheduler
        self.progress = progress
    }

    func prime(_ collectors: [any SurfaceCollector]) async {
        await progress.willBegin(collectors.map(\.surface))
        await withTaskGroup(of: Void.self) { group in
            for collector in collectors {
                guard !Task.isCancelled else { return }
                group.addTask {
                    guard !Task.isCancelled else { return }
                    await scheduler.scheduleAndWait(collector.surface) {
                        guard !Task.isCancelled else { return }
                        await progress.willIndex(collector.surface)
                        await primer.prime(collector)
                        await progress.didIndex(collector.surface)
                    }
                }
            }
        }
        guard !Task.isCancelled else { return }
        await progress.didComplete()
    }
}
