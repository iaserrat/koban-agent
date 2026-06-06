import Foundation

struct SensorHealthRequest: Codable, Hashable {
    var syncBacklogEvents: UInt64
    var syncBacklogBytes: UInt64
}
