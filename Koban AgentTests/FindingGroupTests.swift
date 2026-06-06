import Foundation
import Testing
@testable import Koban_Agent

struct FindingGroupTests {
    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: offset)
    }

    @Test
    func collapsesSameIndicatorOnSameItemIntoOneGroup() {
        let findings = [
            Fixture.finding(ruleID: "ephemeral", itemName: "serena", timestamp: date(300)),
            Fixture.finding(ruleID: "ephemeral", itemName: "serena", timestamp: date(200)),
            Fixture.finding(ruleID: "ephemeral", itemName: "serena", timestamp: date(100))
        ]
        let groups = FindingGroup.grouped(findings)
        #expect(groups.count == 1)
        #expect(groups[0].count == 3)
    }

    @Test
    func representativeIsNewestAndExposesFirstAndLastSeen() {
        let findings = [
            Fixture.finding(ruleID: "ephemeral", itemName: "serena", timestamp: date(300)),
            Fixture.finding(ruleID: "ephemeral", itemName: "serena", timestamp: date(100))
        ]
        let group = FindingGroup.grouped(findings)[0]
        #expect(group.representative.timestamp == date(300))
        #expect(group.lastSeen == date(300))
        #expect(group.firstSeen == date(100))
    }

    @Test
    func keepsDistinctRulesAndItemsApartInFirstAppearanceOrder() {
        let findings = [
            Fixture.finding(ruleID: "ephemeral", itemName: "serena", timestamp: date(400)),
            Fixture.finding(ruleID: "remote", itemName: "serena", timestamp: date(300)),
            Fixture.finding(ruleID: "ephemeral", itemName: "other", timestamp: date(200))
        ]
        let groups = FindingGroup.grouped(findings)
        #expect(groups.count == 3)
        #expect(groups.map(\.representative.ruleID) == ["ephemeral", "remote", "ephemeral"])
    }
}
