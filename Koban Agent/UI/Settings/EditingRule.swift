import Foundation

/// Identifies which rule the editor sheet is editing, by position in the rules array. Indices are
/// stable for the sheet's lifetime (the list is not reordered while a rule is open).
struct EditingRule: Identifiable {
    let index: Int

    var id: Int {
        index
    }
}
