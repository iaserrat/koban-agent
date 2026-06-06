import SwiftUI

// MARK: - StreamColumnWidth

/// Applies a stream column's width to a cell: a fixed width, or - for the one column whose width is
/// `nil` - the flexible frame that absorbs the table's remaining space. Header and body rows share
/// it so their columns always line up.
struct StreamColumnWidth: ViewModifier {
    let width: CGFloat?

    func body(content: Content) -> some View {
        if let width {
            content.frame(width: width, alignment: .leading)
        } else {
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension View {
    func streamColumnWidth(_ width: CGFloat?) -> some View {
        modifier(StreamColumnWidth(width: width))
    }
}
