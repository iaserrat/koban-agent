import Foundation

struct KeychainClientCertificateCredentialProvider: ClientCertificateCredentialProvider {
    private let identityStore: any EnrollmentIdentityStore

    init(identityStore: any EnrollmentIdentityStore = KeychainEnrollmentIdentityStore()) {
        self.identityStore = identityStore
    }

    func credential(certificateData: Data) -> URLCredential? {
        guard let identity = identityStore.identity(certificateData: certificateData) else {
            return nil
        }

        return URLCredential(
            identity: identity,
            certificates: nil,
            persistence: .forSession
        )
    }
}
