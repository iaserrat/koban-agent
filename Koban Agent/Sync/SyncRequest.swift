import Foundation

struct SyncRequest: Codable, Hashable {
    var tenantID: String?
    var deviceID: String
    var sensorVersion: String
    var schemaVersion: Int
    var lastAckedLocalSequence: Int64
    var events: [SyncEventRequest]
    var health: SensorHealthRequest

    private enum CodingKeys: String, CodingKey {
        case tenantID = "tenantId"
        case deviceID = "deviceId"
        case sensorVersion
        case schemaVersion
        case lastAckedLocalSequence
        case events
        case health
    }
}
