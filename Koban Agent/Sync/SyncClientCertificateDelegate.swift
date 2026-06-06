import Foundation

final class SyncClientCertificateDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let stateStore: EnrollmentStateStore
    private let credentialProvider: any ClientCertificateCredentialProvider

    init(
        stateStore: EnrollmentStateStore = EnrollmentStateStore(),
        credentialProvider: any ClientCertificateCredentialProvider =
            KeychainClientCertificateCredentialProvider()
    ) {
        self.stateStore = stateStore
        self.credentialProvider = credentialProvider
    }

    func urlSession(
        _: URLSession,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        disposition(authenticationMethod: challenge.protectionSpace.authenticationMethod)
    }

    func disposition(authenticationMethod: String) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard authenticationMethod == SensorProtocolConstants.clientCertificateAuthenticationMethod,
              let state = try? stateStore.load(),
              let credential = credentialProvider.credential(certificateData: state.clientCertificate)
        else {
            return (.performDefaultHandling, nil)
        }

        return (.useCredential, credential)
    }
}
