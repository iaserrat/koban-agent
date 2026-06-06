import CoreServices
import Testing
@testable import Koban_Agent

struct WatchSignalTests {
    @Test
    func ordinaryEventsRouteToAffectedSurfacesOnly() {
        let plan = watchPlan()
        let signal = WatchSignal(
            events: [
                FSEventsEvent(path: WatchPlan.normalizedPath("~/.codex/config.toml"), flags: 0, identifier: 1)
            ],
            plan: plan
        )

        #expect(signal.surfaces == [.codexConfig])
        #expect(signal.degradationReason == nil)
    }

    @Test
    func droppedEventsRouteToEverySurfaceAndDegradeWatchHealth() {
        let plan = watchPlan()
        let signal = WatchSignal(
            events: [
                FSEventsEvent(
                    path: WatchPlan.normalizedPath("~/.codex/config.toml"),
                    flags: FSEventStreamEventFlags(kFSEventStreamEventFlagKernelDropped),
                    identifier: 1
                )
            ],
            plan: plan
        )

        #expect(signal.surfaces == [.codexConfig, .claudeConfig])
        #expect(signal.degradationReason == HealthMessages.watchEventsDropped)
    }

    @Test
    func rootChangeRoutesToEverySurfaceAndDegradesWatchHealth() {
        let plan = watchPlan()
        let signal = WatchSignal(
            events: [
                FSEventsEvent(
                    path: WatchPlan.normalizedPath("~/.claude.json"),
                    flags: FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged),
                    identifier: 1
                )
            ],
            plan: plan
        )

        #expect(signal.surfaces == [.codexConfig, .claudeConfig])
        #expect(signal.degradationReason == HealthMessages.watchRootChanged)
    }

    @Test
    func wrappedEventIDsRouteToEverySurfaceAndDegradeWatchHealth() {
        let plan = watchPlan()
        let signal = WatchSignal(
            events: [
                FSEventsEvent(
                    path: WatchPlan.normalizedPath("~/.claude.json"),
                    flags: FSEventStreamEventFlags(kFSEventStreamEventFlagEventIdsWrapped),
                    identifier: 1
                )
            ],
            plan: plan
        )

        #expect(signal.surfaces == [.codexConfig, .claudeConfig])
        #expect(signal.degradationReason == HealthMessages.watchEventIDsWrapped)
    }

    private func watchPlan() -> WatchPlan {
        WatchPlanCompiler().compile(
            interests: [
                WatchInterest(surface: .codexConfig, paths: ["~/.codex/config.toml"]),
                WatchInterest(surface: .claudeConfig, paths: ["~/.claude.json"])
            ]
        )
    }
}
