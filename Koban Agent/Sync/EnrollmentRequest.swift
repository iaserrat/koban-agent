import Foundation

struct EnrollmentRequest: Codable, Hashable {
    var token: String
    var publicKey: Data
    var hostname: String
    var osVersion: String
    var hardwareModel: String
    var sensorVersion: String
}
