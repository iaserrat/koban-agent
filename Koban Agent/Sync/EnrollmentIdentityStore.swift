import Foundation
import Security

protocol EnrollmentIdentityStore {
    func publicKeyPEM() throws -> Data
    func identity(certificateData: Data) -> SecIdentity?
}
