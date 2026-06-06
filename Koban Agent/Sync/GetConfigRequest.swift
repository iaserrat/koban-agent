import Foundation

struct GetConfigRequest: Codable, Hashable {
    var tenantID: String
    var deviceID: String
    var currentGeneration: String

    private enum CodingKeys: String, CodingKey {
        case tenantID = "tenantId"
        case deviceID = "deviceId"
        case currentGeneration
    }
}
