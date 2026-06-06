import Foundation

/// Bounded filename matching for documented discovery globs.
enum FilenameMatcher {
    static func matches(name: String, exactNames: Set<String>, globs: [String]) -> Bool {
        exactNames.contains(name) || globs.contains { matches(name: name, glob: $0) }
    }

    private static func matches(name: String, glob: String) -> Bool {
        let parts = glob.split(separator: "*", omittingEmptySubsequences: false).map(String.init)
        guard parts.count > 1 else { return name == glob }

        var remainder = name[...]
        for (index, part) in parts.enumerated() where part.isEmpty == false {
            guard let range = remainder.range(of: part) else { return false }
            if index == parts.startIndex, range.lowerBound != remainder.startIndex {
                return false
            }
            remainder = remainder[range.upperBound...]
        }

        if let last = parts.last, last.isEmpty == false {
            return name.hasSuffix(last)
        }
        return true
    }
}
