import Foundation

/// Which field of a `StreamRow` a table column draws. The row view switches on this to build the
/// cell, so a scope describes its table purely as data (`MonitorScope.columns`) with no view code.
enum StreamColumnKind: Hashable {
    case time
    case event
    case surface
    case context
    case detail
    case version
    case origin
    case severity
    case flag
}
