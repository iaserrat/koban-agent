import Foundation

struct SurfaceScanQueueState: Hashable {
    var surface: MonitoredSurface
    var isRunning: Bool
    var runningScanID: UUID?
    var hasPendingScan: Bool
    var coalescedTriggerCount: Int
}
