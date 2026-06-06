import Foundation

struct CheckInRequest: Codable, Hashable {
    var tenantID: String
    var deviceID: String
    var sensorVersion: String
    var osVersion: String
    var activeConfigGeneration: String
    var health: SensorHealthRequest

    private enum CodingKeys: String, CodingKey {
        case tenantID = "tenantId"
        case deviceID = "deviceId"
        case sensorVersion
        case osVersion
        case activeConfigGeneration
        case health
    }
}
