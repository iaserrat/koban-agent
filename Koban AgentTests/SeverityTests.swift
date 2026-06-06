import Testing
@testable import Koban_Agent

struct SeverityTests {
    @Test
    func ordersFromInfoToCritical() {
        #expect(Severity.info < Severity.notable)
        #expect(Severity.notable < Severity.suspicious)
        #expect(Severity.suspicious < Severity.critical)
    }

    @Test
    func maxPicksMostUrgent() {
        let severities: [Severity] = [.info, .critical, .suspicious, .notable]
        #expect(severities.max() == .critical)
    }
}
