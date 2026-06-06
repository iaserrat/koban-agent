import Foundation

/// One column in the monitor's stream table: which field it draws, its header text, and its width.
/// A `nil` width marks the single flexible column that absorbs the table's remaining space.
struct StreamColumn: Identifiable, Hashable {
    let kind: StreamColumnKind
    let title: String
    let width: CGFloat?

    var id: StreamColumnKind {
        kind
    }
}
