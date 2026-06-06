import Foundation

struct WatchPlan {
    var paths: [String]
    var interests: [WatchInterest]

    init(paths: [String], interests: [WatchInterest]) {
        self.paths = Self.orderedUniquePaths(paths.map(Self.normalizedPath))
        self.interests = interests.map { interest in
            WatchInterest(
                surface: interest.surface,
                paths: Self.orderedUniquePaths(interest.paths.map(Self.normalizedPath))
            )
        }
    }

    func affectedSurfaces(for events: [FSEventsEvent]) -> Set<MonitoredSurface> {
        guard events.isEmpty == false else {
            return Set(interests.map(\.surface))
        }

        let eventPaths = events.map { Self.normalizedPath($0.path) }
        return Set(interests.compactMap { interest in
            let hasMatch = eventPaths.contains { eventPath in
                interest.paths.contains { Self.path(eventPath, isEqualToOrDescendantOf: $0) }
            }
            return hasMatch ? interest.surface : nil
        })
    }

    static func normalizedPath(_ path: String) -> String {
        let expanded = NSString(string: path).expandingTildeInPath
        return NSString(string: expanded).standardizingPath
    }

    private static func orderedUniquePaths(_ paths: [String]) -> [String] {
        var seen: Set<String> = []
        return paths.filter { path in
            seen.insert(path).inserted
        }
    }

    static func path(_ candidate: String, isEqualToOrDescendantOf root: String) -> Bool {
        candidate == root
            || root == PathConstants.separator
            || candidate.hasPrefix(root + PathConstants.separator)
    }
}
