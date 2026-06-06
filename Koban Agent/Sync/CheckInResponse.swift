import Foundation

struct CheckInResponse: Codable, Hashable {
    var serverTime: String
    var configGeneration: String
    var configUpdateAvailable: Bool
    var certificateRenewalRequired: Bool
    var fullResnapshotRequested: Bool
}
