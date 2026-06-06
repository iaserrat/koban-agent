import Observation

/// First-run flow state: which step is on screen, and the live indexing progress reported by the
/// engine's startup primer. `@MainActor` because every read happens during view rendering;
/// `@Observable` so each step view tracks only the fields it touches. The app delegate owns one
/// instance and feeds it from the engine's `IndexingProgress` hook.
@MainActor
@Observable
final class OnboardingModel {
    /// The three first-run steps, in order. Welcome and surfaces are read at the user's pace; the
    /// indexing step runs the engine's first load and lands on its completed summary.
    enum Step: Int, CaseIterable {
        case welcome
        case surfaces
        case indexing
    }

    /// One surface's place in the first load.
    enum IndexingState {
        case pending
        case indexing
        case indexed
    }

    private(set) var step: Step = .welcome

    /// The surfaces being indexed, in collector order, set once the engine reports `willBegin`.
    private(set) var surfaces: [MonitoredSurface] = []
    private(set) var states: [MonitoredSurface: IndexingState] = [:]

    /// True once every surface has been primed, so the indexing step can reveal its summary.
    private(set) var isIndexingComplete = false

    /// How many surfaces have finished, for the progress bar and summary count.
    var indexedCount: Int {
        states.values.count { $0 == .indexed }
    }

    /// Indexing progress as a 0...1 fraction. Zero before the engine reports its surface set.
    var progress: Double {
        guard surfaces.isEmpty == false else { return 0 }
        return Double(indexedCount) / Double(surfaces.count)
    }

    func state(for surface: MonitoredSurface) -> IndexingState {
        states[surface] ?? .pending
    }

    func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    // MARK: - Indexing progress, driven by the engine

    func beginIndexing(_ surfaces: [MonitoredSurface]) {
        self.surfaces = surfaces
        states = Dictionary(uniqueKeysWithValues: surfaces.map { ($0, .pending) })
        isIndexingComplete = false
    }

    func markIndexing(_ surface: MonitoredSurface) {
        states[surface] = .indexing
    }

    func markIndexed(_ surface: MonitoredSurface) {
        states[surface] = .indexed
    }

    func completeIndexing() {
        for surface in surfaces {
            states[surface] = .indexed
        }
        isIndexingComplete = true
    }
}
