import Foundation

/// The "Event" column's content for a row: the kind of change in the activity scope, the rule
/// headline in the findings scope, or nothing in the inventory scope (where the surface and name
/// already identify the row).
enum StreamBadge: Hashable {
    case change(ChangeKind)
    case rule(String)
    case blank
}
