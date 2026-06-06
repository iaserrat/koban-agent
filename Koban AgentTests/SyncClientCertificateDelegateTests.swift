import Foundation
import Testing
@testable import Koban_Agent

// MARK: - SyncClientCertificateDelegateTests

struct SyncClientCertificateDelegateTests {
    private static let tenantID = "tenant-a"
    private static let deviceID = "device-a"
    private static let certificateData = Data("certificate-a".utf8)
    private static let certificateExpiresAt = "2026-06-01T10:00:00Z"
    private static let serverTrustAuthenticationMethod = NSURLAuthenticationMethodServerTrust

    @Test
    func usesCredentialForClientCertificateChallenge() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateStore = try stateStoreWithEnrollment(directory: directory)
            let credential = URLCredential(user: "sensor", password: "secret", persistence: .forSession)
            let provider = FakeClientCertificateCredentialProvider(credential: credential)
            let delegate = SyncClientCertificateDelegate(
                stateStore: stateStore,
                credentialProvider: provider
            )

            let result = delegate.disposition(
                authenticationMethod: SensorProtocolConstants.clientCertificateAuthenticationMethod
            )

            #expect(result.0 == .useCredential)
            #expect(result.1 === credential)
            #expect(provider.requestedCertificateData == Self.certificateData)
        }
    }

    @Test
    func fallsBackForNonClientCertificateChallenge() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateStore = try stateStoreWithEnrollment(directory: directory)
            let provider = FakeClientCertificateCredentialProvider(
                credential: URLCredential(user: "sensor", password: "secret", persistence: .forSession)
            )
            let delegate = SyncClientCertificateDelegate(
                stateStore: stateStore,
                credentialProvider: provider
            )

            let result = delegate.disposition(authenticationMethod: Self.serverTrustAuthenticationMethod)

            #expect(result.0 == .performDefaultHandling)
            #expect(result.1 == nil)
            #expect(provider.requestedCertificateData == nil)
        }
    }

    @Test
    func fallsBackWhenEnrollmentStateIsMissing() async {
        await Fixture.withTemporaryDirectory { directory in
            let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let provider = FakeClientCertificateCredentialProvider(
                credential: URLCredential(user: "sensor", password: "secret", persistence: .forSession)
            )
            let delegate = SyncClientCertificateDelegate(
                stateStore: EnrollmentStateStore(fileURL: stateURL),
                credentialProvider: provider
            )

            let result = delegate.disposition(
                authenticationMethod: SensorProtocolConstants.clientCertificateAuthenticationMethod
            )

            #expect(result.0 == .performDefaultHandling)
            #expect(result.1 == nil)
            #expect(provider.requestedCertificateData == nil)
        }
    }

    @Test
    func fallsBackWhenCredentialProviderCannotBuildCredential() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateStore = try stateStoreWithEnrollment(directory: directory)
            let provider = FakeClientCertificateCredentialProvider(credential: nil)
            let delegate = SyncClientCertificateDelegate(
                stateStore: stateStore,
                credentialProvider: provider
            )

            let result = delegate.disposition(
                authenticationMethod: SensorProtocolConstants.clientCertificateAuthenticationMethod
            )

            #expect(result.0 == .performDefaultHandling)
            #expect(result.1 == nil)
            #expect(provider.requestedCertificateData == Self.certificateData)
        }
    }

    private func stateStoreWithEnrollment(directory: URL) throws -> EnrollmentStateStore {
        let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
        let store = EnrollmentStateStore(fileURL: stateURL)
        try store.save(EnrollmentState(
            tenantID: Self.tenantID,
            deviceID: Self.deviceID,
            clientCertificate: Self.certificateData,
            certificateExpiresAt: Self.certificateExpiresAt,
            configGeneration: nil
        ))
        return store
    }
}

// MARK: - FakeClientCertificateCredentialProvider

private final class FakeClientCertificateCredentialProvider: ClientCertificateCredentialProvider {
    private let credential: URLCredential?
    private(set) var requestedCertificateData: Data?

    init(credential: URLCredential?) {
        self.credential = credential
    }

    func credential(certificateData: Data) -> URLCredential? {
        requestedCertificateData = certificateData
        return credential
    }
}
