import Foundation
import Testing
@testable import Koban_Agent

struct EventGroupTests {
    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: offset)
    }

    @Test
    func collapsesIdenticalEventsAndCountsThem() {
        let events = [
            Fixture.event(itemName: "serena", detail: "uvx", timestamp: date(300)),
            Fixture.event(itemName: "serena", detail: "uvx", timestamp: date(200)),
            Fixture.event(itemName: "serena", detail: "uvx", timestamp: date(100))
        ]
        let groups = EventGroup.grouped(events)
        #expect(groups.count == 1)
        #expect(groups[0].count == 3)
        #expect(groups[0].lastSeen == date(300))
    }

    @Test
    func differentDetailsAreDistinctGroups() {
        let events = [
            Fixture.event(itemName: "serena", detail: "uvx", timestamp: date(300)),
            Fixture.event(itemName: "serena", detail: "npx", timestamp: date(200))
        ]
        #expect(EventGroup.grouped(events).count == 2)
    }
}
