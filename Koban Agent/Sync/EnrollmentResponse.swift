import Foundation

struct EnrollmentResponse: Codable, Hashable {
    var tenantID: String
    var deviceID: String
    var clientCertificate: Data
    var certificateExpiresAt: String

    private enum CodingKeys: String, CodingKey {
        case tenantID = "tenantId"
        case deviceID = "deviceId"
        case clientCertificate
        case certificateExpiresAt
    }
}
