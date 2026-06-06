import Foundation

struct EnrollmentState: Codable, Hashable {
    var tenantID: String
    var deviceID: String
    var clientCertificate: Data
    var certificateExpiresAt: String
    var configGeneration: String?
}
