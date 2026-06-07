import Foundation
import Testing
@testable import Koban_Agent

struct EnrollmentStateStoreTests {
    @Test
    func deleteRemovesSavedEnrollmentState() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let fileURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let store = EnrollmentStateStore(fileURL: fileURL)

            try store.save(enrollmentState())
            #expect(try store.load()?.deviceID == "device-a")

            try store.delete()

            #expect(try store.load() == nil)
        }
    }

    @Test
    func deleteMissingEnrollmentStateIsNoop() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let fileURL = directory.appending(component: SensorProtocolConstants.enrollmentStateFileName)
            let store = EnrollmentStateStore(fileURL: fileURL)

            try store.delete()

            #expect(try store.load() == nil)
        }
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
