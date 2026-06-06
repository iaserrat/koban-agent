import Foundation
import Testing
@testable import Koban_Agent

struct PresentRuleConfigurationDecodingTests {
    private func decode(_ json: String) throws -> KobanConfiguration {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(KobanConfiguration.self, from: data)
    }

    @Test
    func decodesPresentRuleTrigger() throws {
        let json = #"""
        {
          "rules": [
            {
              "id": "custom.present",
              "surface": "homebrew",
              "enabled": true,
              "triggers": ["present"],
              "severity": "critical",
              "title": "Custom",
              "rationale": "Why",
              "match": "fieldContainsAny",
              "field": "name",
              "values": ["copilot-for-xcode"]
            }
          ]
        }
        """#
        let config = try decode(json)
        let rule = try #require(config.rules.first)
        #expect(rule.triggers == [RuleTrigger.present])
        #expect(rule.match.matches(Fixture.item(name: "copilot-for-xcode")))
    }
}
