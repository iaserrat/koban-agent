import Foundation

struct SurfaceFreshnessPolicy: Hashable {
    var maxAgeSeconds: Int

    func displayState(for health: SurfaceHealth?, now: Date) -> SurfaceHealthState {
        guard let health else { return .idle }
        guard health.state == .healthy else { return health.state }
        guard let lastSuccessfulScanAt = health.lastSuccessfulScanAt else { return .stale }

        let staleAfter = Date(
            timeInterval: TimeInterval(maxAgeSeconds),
            since: lastSuccessfulScanAt
        )
        return now > staleAfter ? .stale : .healthy
    }
}
