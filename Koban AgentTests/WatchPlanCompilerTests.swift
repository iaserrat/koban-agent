import Testing
@testable import Koban_Agent

struct WatchPlanCompilerTests {
    @Test
    func watchPlanStoresCanonicalUniquePaths() {
        let plan = WatchPlan(
            paths: ["~/.codex/../.codex", "~/.codex"],
            interests: [
                WatchInterest(
                    surface: .codexConfig,
                    paths: ["~/.codex/../.codex/config.toml", "~/.codex/config.toml"]
                )
            ]
        )

        #expect(plan.paths == [WatchPlan.normalizedPath("~/.codex")])
        #expect(plan.interests.map(\.paths) == [[WatchPlan.normalizedPath("~/.codex/config.toml")]])
    }

    @Test
    func deduplicatesAndNormalizesWatchPaths() {
        let plan = WatchPlanCompiler().compile(
            interests: [
                WatchInterest(
                    surface: .codexConfig,
                    paths: ["~/.codex/config.toml", "~/.codex/../.codex/config.toml"]
                )
            ]
        )

        #expect(plan.paths == [WatchPlan.normalizedPath("~/.codex/config.toml")])
    }

    @Test
    func prunesDescendantPathsWhenAncestorIsAlreadyWatched() {
        let root = WatchPlan.normalizedPath("~/.codex")
        let child = WatchPlan.normalizedPath("~/.codex/config.toml")

        let plan = WatchPlanCompiler().compile(
            interests: [
                WatchInterest(surface: .codexConfig, paths: [child, root])
            ]
        )

        #expect(plan.paths == [root])
    }

    @Test
    func routesChangedPathsToInterestedSurfacesOnly() {
        let codexPath = WatchPlan.normalizedPath("~/.codex/config.toml")
        let claudePath = WatchPlan.normalizedPath("~/.claude.json")
        let plan = WatchPlanCompiler().compile(
            interests: [
                WatchInterest(surface: .codexConfig, paths: [codexPath]),
                WatchInterest(surface: .claudeConfig, paths: [claudePath])
            ]
        )

        let surfaces = plan.affectedSurfaces(
            for: [
                FSEventsEvent(path: codexPath, flags: 0, identifier: 1)
            ]
        )

        #expect(surfaces == [.codexConfig])
    }

    @Test
    func emptyEventBatchesRouteToEveryInterestedSurface() {
        let plan = WatchPlanCompiler().compile(
            interests: [
                WatchInterest(surface: .codexConfig, paths: ["~/.codex/config.toml"]),
                WatchInterest(surface: .claudeConfig, paths: ["~/.claude.json"])
            ]
        )

        #expect(plan.affectedSurfaces(for: []) == [.codexConfig, .claudeConfig])
    }
}
