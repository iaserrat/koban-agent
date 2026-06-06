// MARK: - ScanFailureRecordingError

struct ScanFailureRecordingError: Error, CustomStringConvertible {
    let scanError: any Error
    let healthError: any Error

    var description: String {
        HealthMessages.scanFailureRecordingFailed(
            scanError: scanError,
            healthError: healthError
        )
    }
}
