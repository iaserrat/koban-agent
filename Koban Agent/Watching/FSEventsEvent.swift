import CoreServices
import Foundation

/// A single FSEvents notification after bridging from the C callback.
struct FSEventsEvent: Hashable {
    var path: String
    var flags: FSEventStreamEventFlags
    var identifier: FSEventStreamEventId
}
