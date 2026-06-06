import Foundation

/// The window's loaded data, bundled so the pure row builder takes one input rather than three
/// parallel lists. The view model fills it from `WindowDataModel`; the builder reads it and returns
/// rows, keeping the projection a pure function of its input.
struct MonitorData {
    var activity: [ChangeEvent]
    var findingGroups: [FindingGroup]
    var inventories: [MonitoredSurface: [InventoryItem]]

    static let empty = Self(activity: [], findingGroups: [], inventories: [:])
}
