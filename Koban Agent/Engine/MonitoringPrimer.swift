import OSLog

// MARK: - MonitoringPrimer

struct MonitoringPrimer {
    private let primeSurface: @Sendable (any SurfaceCollector) async -> Void

    init(inventory: InventoryRepository, scanner: MonitoringScanner) {
        primeSurface = { collector in
            do {
                if try inventory.isBaselined(collector.surface) {
                    try await scanner.runPipeline(collector)
                } else {
                    try await scanner.establishBaseline(collector)
                }
            } catch is CancellationError {
                return
            } catch {
                Log.engine.error("Priming \(collector.surface.rawValue, privacy: .public) failed: \(error).")
            }
        }
    }

    init(prime: @escaping @Sendable (any SurfaceCollector) async -> Void) {
        primeSurface = prime
    }

    func prime(_ collector: any SurfaceCollector) async {
        guard !Task.isCancelled else { return }
        await primeSurface(collector)
    }
}
