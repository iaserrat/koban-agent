import Foundation
import Testing
@testable import Koban_Agent

struct SyncIdentityResetterTests {
    @Test
    func surfacesErrorWhenReenrollmentDoesNotReestablishIdentity() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let store = EnrollmentStateStore(fileURL: stateURL)
            try store.save(enrollmentState())
            // Bootstrap that fails to enroll: it leaves no saved identity behind, the offline case.
            let resetter = SyncIdentityResetter(stateStore: store) { $0 }

            await #expect(throws: SyncResetError.reenrollmentFailed) {
                _ = try await resetter.reset(enrollingConfiguration())
            }
            #expect(try store.load() == nil)
        }
    }

    @Test
    func returnsBootstrappedConfigurationWhenReenrollmentSucceeds() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let store = EnrollmentStateStore(fileURL: stateURL)
            // Bootstrap that re-establishes identity, the online case.
            let resetter = SyncIdentityResetter(stateStore: store) { configuration in
                try? store.save(enrollmentState())
                var effective = configuration
                effective.sync.tenantID = "tenant-a"
                effective.sync.deviceID = "device-a"
                return effective
            }

            let result = try await resetter.reset(enrollingConfiguration())

            #expect(result.sync.tenantID == "tenant-a")
            #expect(result.sync.deviceID == "device-a")
        }
    }

    @Test
    func doesNotRequireEnrollmentWhenSyncDisabled() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let stateURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let store = EnrollmentStateStore(fileURL: stateURL)
            try store.save(enrollmentState())
            let resetter = SyncIdentityResetter(stateStore: store) { $0 }

            var configuration = enrollingConfiguration()
            configuration.sync.enabled = false

            // No throw even though no identity is re-established: a disabled sensor does not enroll.
            _ = try await resetter.reset(configuration)
            #expect(try store.load() == nil)
        }
    }

    private func enrollingConfiguration() -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.sync.enabled = true
        configuration.sync.endpoint = "https://fleet.example.com"
        configuration.sync.enrollmentToken = "token-a"
        return configuration
    }

    private func enrollmentState() -> EnrollmentState {
        EnrollmentState(
            tenantID: "tenant-a",
            deviceID: "device-a",
            clientCertificate: Data("certificate".utf8),
            certificateExpiresAt: "2026-06-01T10:00:00Z",
            configGeneration: nil
        )
    }
}
