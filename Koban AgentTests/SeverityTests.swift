import Testing
@testable import Koban_Agent

struct SeverityTests {
    @Test
    func ordersFromInfoToSuspicious() {
        #expect(Severity.info < Severity.notable)
        #expect(Severity.notable < Severity.suspicious)
    }

    @Test
    func maxPicksMostUrgent() {
        let severities: [Severity] = [.info, .suspicious, .notable]
        #expect(severities.max() == .suspicious)
    }
}
