import Testing
@testable import Koban_Agent

struct RuleMatchTests {
    @Test
    func alwaysMatches() {
        #expect(RuleMatch.always.matches(Fixture.item(name: "x")))
    }

    @Test
    func fieldContainsAnyIsCaseInsensitive() {
        let item = Fixture.item(name: "srv", detail: "NPX -y foo")
        let match = RuleMatch.fieldContainsAny(field: .detail, values: ["npx"])
        #expect(match.matches(item))
    }

    @Test
    func fieldContainsAnyMissesWhenAbsent() {
        let item = Fixture.item(name: "srv", detail: "node server.js")
        let match = RuleMatch.fieldContainsAny(field: .detail, values: ["npx", "curl"])
        #expect(match.matches(item) == false)
    }

    @Test
    func fieldNotInListFlagsValuesOutsideAllowList() {
        let item = Fixture.item(name: "x", origin: "thirdparty/tap")
        let match = RuleMatch.fieldNotInList(field: .origin, allowed: ["homebrew/core"])
        #expect(match.matches(item))
    }

    @Test
    func fieldNotInListPassesAllowedValues() {
        let item = Fixture.item(name: "x", origin: "homebrew/core")
        let match = RuleMatch.fieldNotInList(field: .origin, allowed: ["homebrew/core"])
        #expect(match.matches(item) == false)
    }

    @Test
    func fieldHasURLSchemeMatchesRemoteTransport() {
        let item = Fixture.item(name: "srv", detail: "https://mcp.example.com")
        let match = RuleMatch.fieldHasURLScheme(field: .detail, schemes: ["https"])
        #expect(match.matches(item))
    }

    @Test
    func fieldHasURLSchemeIgnoresLocalCommands() {
        let item = Fixture.item(name: "srv", detail: "npx -y foo")
        let match = RuleMatch.fieldHasURLScheme(field: .detail, schemes: ["http", "https"])
        #expect(match.matches(item) == false)
    }

    @Test
    func flagEqualsComparesTriState() {
        let dependency = Fixture.item(name: "x", installedOnRequest: false)
        let requested = Fixture.item(name: "y", installedOnRequest: true)
        let absent = Fixture.item(name: "z", installedOnRequest: nil)
        let match = RuleMatch.flagEquals(flag: .installedOnRequest, expected: false)
        #expect(match.matches(dependency))
        #expect(match.matches(requested) == false)
        #expect(match.matches(absent) == false)
    }
}
