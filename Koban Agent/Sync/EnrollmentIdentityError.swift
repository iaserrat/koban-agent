import Foundation

enum EnrollmentIdentityError: Error, Equatable {
    case keyCreationFailed
    case keyLookupFailed(OSStatus)
    case publicKeyUnavailable
    case publicKeyExportFailed
    case invalidPublicKeyPrefix
    case invalidCertificate
}
