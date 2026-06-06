import Foundation

enum SyncUploadError: Error, Equatable {
    case missingEndpoint
    case invalidEndpoint(String)
    case invalidResponse
    case serverStatus(Int)
}
