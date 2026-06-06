struct WatchPlanCompiler {
    func compile(interests: [WatchInterest]) -> WatchPlan {
        let normalizedInterests = interests.map { interest in
            WatchInterest(
                surface: interest.surface,
                paths: uniqueSorted(interest.paths.map(WatchPlan.normalizedPath))
            )
        }
        let paths = uniqueSorted(normalizedInterests.flatMap(\.paths))
        return WatchPlan(paths: pruneDescendantPaths(paths), interests: normalizedInterests)
    }

    private func pruneDescendantPaths(_ paths: [String]) -> [String] {
        paths.reduce(into: []) { result, path in
            guard result.contains(where: {
                WatchPlan.path(path, isEqualToOrDescendantOf: $0)
            }) == false else { return }
            result.append(path)
        }
    }

    private func uniqueSorted(_ paths: [String]) -> [String] {
        Array(Set(paths)).sorted()
    }
}
