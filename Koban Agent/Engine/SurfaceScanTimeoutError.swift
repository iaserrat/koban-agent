import Foundation

struct SurfaceScanTimeoutError: Error, CustomStringConvertible, Equatable {
    let seconds: Int

    var description: String {
        HealthMessages.scanTimedOut(seconds: seconds)
    }
}
