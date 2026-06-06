import Foundation

/// Groups elements by a key, preserving both the order in which each key first appears and the
/// order of elements within each group. Pure and generic, so finding and event grouping share
/// one implementation rather than each reimplementing the bucketing (see CLAUDE.md).
enum OrderedGrouping {
    static func grouped<Element, Key: Hashable>(
        _ elements: [Element],
        by key: (Element) -> Key
    ) -> [[Element]] {
        var order: [Key] = []
        var buckets: [Key: [Element]] = [:]
        for element in elements {
            let elementKey = key(element)
            if buckets[elementKey] == nil { order.append(elementKey) }
            buckets[elementKey, default: []].append(element)
        }
        return order.compactMap { buckets[$0] }
    }
}
