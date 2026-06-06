import Foundation
import Testing
@testable import Koban_Agent

// MARK: - SurfaceFreshnessPolicyTests

struct SurfaceFreshnessPolicyTests {
    @Test
    func marksHealthySurfaceStaleWhenLastSuccessExceedsFreshnessBudget() {
        let policy = SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        let health = SurfaceHealth(
            surface: .homebrew,
            state: .healthy,
            lastSuccessfulScanAt: Date(timeIntervalSince1970: 1)
        )
        let now = Date(timeIntervalSince1970: 12)

        #expect(policy.displayState(for: health, now: now) == .stale)
    }

    @Test
    func keepsFreshHealthySurfaceHealthy() {
        let policy = SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        let health = SurfaceHealth(
            surface: .homebrew,
            state: .healthy,
            lastSuccessfulScanAt: Date(timeIntervalSince1970: 1)
        )
        let now = Date(timeIntervalSince1970: 11)

        #expect(policy.displayState(for: health, now: now) == .healthy)
    }

    @Test
    func doesNotHideDegradedStateBehindStaleness() {
        let policy = SurfaceFreshnessPolicy(maxAgeSeconds: 10)
        let health = SurfaceHealth(
            surface: .homebrew,
            state: .degraded,
            lastSuccessfulScanAt: Date(timeIntervalSince1970: 1)
        )
        let now = Date(timeIntervalSince1970: 12)

        #expect(policy.displayState(for: health, now: now) == .degraded)
    }
}
