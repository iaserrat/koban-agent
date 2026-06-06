import Foundation
import Testing
@testable import Koban_Agent

// MARK: - InstallReceiptCancellationTests

struct InstallReceiptCancellationTests {
    @Test
    func cancelledTaskStopsKegReceiptRead() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let receiptURL = directory.appending(path: KnownPaths.homebrewInstallReceiptName)
            try #"{"source":{"tap":"homebrew/core"},"installed_on_request":true}"#
                .write(to: receiptURL, atomically: true, encoding: .utf8)
            let task = Task {
                try InstallReceipt.read(inKeg: directory)
            }
            task.cancel()

            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        }
    }
}
