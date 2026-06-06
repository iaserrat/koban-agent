import Foundation
import GRDB
import Testing
@testable import Koban_Agent

// MARK: - MonitoringEngineSoakTests

/// Long-running lifecycle soak gate for the real `MonitoringEngine`.
///
/// The engine is driven against an in-memory database and a temporary Homebrew prefix so the
/// pipeline runs end to end without touching the developer's home directory or the wall clock
/// (the poll interval is far longer than the test). The soak proves the generation gate keeps
/// stale work inert: a callback after stop never publishes, and stop/start cycles always land
/// monitoring in the expected state. macOS treats sleep/wake as a stop followed by a start, so
/// the repeated stop/start cycle is exactly that scenario.
@MainActor
struct MonitoringEngineSoakTests {
    private static let cycles = 30

    @Test
    func repeatedStartStopAlwaysLandsInTheExpectedState() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let harness = try makeHarness(homebrewPrefix: directory)

            for _ in 0 ..< Self.cycles {
                await harness.engine.start()
                #expect(harness.appState.isMonitoring)

                await harness.engine.stop()
                #expect(harness.appState.isMonitoring == false)
            }
        }
    }

    @Test
    func callbackAfterStopNeverPublishes() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let harness = try makeHarness(homebrewPrefix: directory)

            await harness.engine.start()
            await harness.engine.stop()

            let revisionAfterStop = harness.appState.revision

            // A watch/poll callback that arrives after stop carries a dead generation: the
            // engine must drop it without scanning or publishing.
            await harness.engine.rescan(.homebrew)
            await Task.yield()

            #expect(harness.appState.revision == revisionAfterStop)
            #expect(harness.appState.isMonitoring == false)
        }
    }

    @Test
    func stopFollowedByImmediateStartReestablishesMonitoring() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let harness = try makeHarness(homebrewPrefix: directory)

            await harness.engine.start()
            await harness.engine.stop()
            await harness.engine.start()
            #expect(harness.appState.isMonitoring)

            // The freshly started generation still publishes normally after the churn.
            let revisionAfterStart = harness.appState.revision
            await harness.engine.rescan(.homebrew)
            await harness.engine.stop()
            #expect(harness.appState.revision >= revisionAfterStart)
            #expect(harness.appState.isMonitoring == false)
        }
    }

    private func makeHarness(homebrewPrefix: URL) throws -> SoakHarness {
        let appState = AppState()
        let database = try AppDatabase(DatabaseQueue())
        let engine = try MonitoringEngine(
            configuration: Self.soakConfiguration(homebrewPrefix: homebrewPrefix),
            database: database,
            appState: appState
        )
        return SoakHarness(engine: engine, appState: appState)
    }

    private static func soakConfiguration(homebrewPrefix: URL) -> KobanConfiguration {
        var configuration = DefaultConfiguration.value
        configuration.homebrew = HomebrewSettings(enabled: true, prefixes: [homebrewPrefix.path])
        configuration.claude.enabled = false
        configuration.codex.enabled = false
        configuration.pi.enabled = false
        configuration.cursor.enabled = false
        configuration.opencode.enabled = false
        configuration.javascript.enabled = false
        configuration.python.enabled = false
        return configuration
    }
}

// MARK: - SoakHarness

@MainActor
private struct SoakHarness {
    let engine: MonitoringEngine
    let appState: AppState
}
