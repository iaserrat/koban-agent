import Foundation

enum SyncEventState: String, Codable {
    case pending
    case inFlight
    case acked
    case poison
}
