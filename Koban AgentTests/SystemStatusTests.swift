import Testing
@testable import Koban_Agent

struct SystemStatusTests {
    @Test
    func readModelFailureOutranksEverything() {
        let status = SystemStatus.evaluate(
            readModelFailed: true,
            isMonitoring: true,
            hasCompletedInitialScan: true,
            overallHealth: .degraded,
            worstFindingSeverity: .critical
        )
        #expect(status == .dataUnavailable)
    }

    @Test
    func notMonitoringReadsAsStarting() {
        let status = SystemStatus.evaluate(
            readModelFailed: false,
            isMonitoring: false,
            hasCompletedInitialScan: true,
            overallHealth: .healthy,
            worstFindingSeverity: nil
        )
        #expect(status == .starting)
    }

    @Test
    func beforeFirstScanReadsAsStarting() {
        let status = SystemStatus.evaluate(
            readModelFailed: false,
            isMonitoring: true,
            hasCompletedInitialScan: false,
            overallHealth: .idle,
            worstFindingSeverity: nil
        )
        #expect(status == .starting)
    }

    @Test
    func degradedHealthGatesFindings() {
        let status = SystemStatus.evaluate(
            readModelFailed: false,
            isMonitoring: true,
            hasCompletedInitialScan: true,
            overallHealth: .degraded,
            worstFindingSeverity: .critical
        )
        #expect(status == .degraded)
    }

    @Test
    func findingsCarryTheWorstSeverityWhenHealthy() {
        let status = SystemStatus.evaluate(
            readModelFailed: false,
            isMonitoring: true,
            hasCompletedInitialScan: true,
            overallHealth: .stale,
            worstFindingSeverity: .suspicious
        )
        #expect(status == .findings(.suspicious))
    }

    @Test
    func liveHealthyAndUnflaggedReadsAsAllClear() {
        let status = SystemStatus.evaluate(
            readModelFailed: false,
            isMonitoring: true,
            hasCompletedInitialScan: true,
            overallHealth: .healthy,
            worstFindingSeverity: nil
        )
        #expect(status == .allClear)
    }
}
