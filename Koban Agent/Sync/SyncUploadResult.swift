import Foundation

struct SyncUploadResult: Equatable {
    var uploadedEventCount: Int
    var acceptedEventCount: Int
    var rejectedEventCount: Int
    var retryEventCount: Int
    var configUpdateAvailable: Bool
    var fullResnapshotRequested: Bool

    static let empty = Self(
        uploadedEventCount: 0,
        acceptedEventCount: 0,
        rejectedEventCount: 0,
        retryEventCount: 0,
        configUpdateAvailable: false,
        fullResnapshotRequested: false
    )
}
