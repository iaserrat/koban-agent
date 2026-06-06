import CoreServices
import Foundation

struct WatchSignal {
    var surfaces: Set<MonitoredSurface>
    var degradationReason: String?

    init(surfaces: Set<MonitoredSurface>, degradationReason: String?) {
        self.surfaces = surfaces
        self.degradationReason = degradationReason
    }

    init(events: [FSEventsEvent], plan: WatchPlan) {
        if let reason = Self.degradationReason(for: events) {
            surfaces = Set(plan.interests.map(\.surface))
            degradationReason = reason
        } else {
            surfaces = plan.affectedSurfaces(for: events)
            degradationReason = nil
        }
    }

    func merged(with signal: Self) -> Self {
        Self(
            surfaces: surfaces.union(signal.surfaces),
            degradationReason: Self.strongestDegradationReason(degradationReason, signal.degradationReason)
        )
    }

    private static func strongestDegradationReason(_ lhs: String?, _ rhs: String?) -> String? {
        let reasons = [lhs, rhs]
        if reasons.contains(HealthMessages.watchEventsDropped) {
            return HealthMessages.watchEventsDropped
        }
        if reasons.contains(HealthMessages.watchEventIDsWrapped) {
            return HealthMessages.watchEventIDsWrapped
        }
        if reasons.contains(HealthMessages.watchRootChanged) { return HealthMessages.watchRootChanged }
        return nil
    }

    private static func degradationReason(for events: [FSEventsEvent]) -> String? {
        let flags = events.reduce(FSEventStreamEventFlags()) { partial, event in
            partial | event.flags
        }

        if hasAnyFlag(
            kFSEventStreamEventFlagUserDropped,
            kFSEventStreamEventFlagKernelDropped,
            kFSEventStreamEventFlagMustScanSubDirs,
            in: flags
        ) {
            return HealthMessages.watchEventsDropped
        }

        if hasFlag(kFSEventStreamEventFlagEventIdsWrapped, in: flags) {
            return HealthMessages.watchEventIDsWrapped
        }

        if hasFlag(kFSEventStreamEventFlagRootChanged, in: flags) {
            return HealthMessages.watchRootChanged
        }

        return nil
    }

    private static func hasAnyFlag(_ candidates: Int..., in flags: FSEventStreamEventFlags) -> Bool {
        candidates.contains { hasFlag($0, in: flags) }
    }

    private static func hasFlag(_ flag: Int, in flags: FSEventStreamEventFlags) -> Bool {
        flags & FSEventStreamEventFlags(flag) != 0
    }
}
