import Foundation
import Testing
import Yams
@testable import Koban_Agent

struct DefaultConfigurationResourceTests {
    @Test
    func shippedDefaultYAMLDecodesCoreDefaults() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Koban Agent/Resources/koban.default.yaml")
        let data = try Data(contentsOf: url)

        let config = try YAMLDecoder().decode(KobanConfiguration.self, from: data)

        var actualCore = config
        var expectedCore = DefaultConfiguration.value
        let actualRules = Set(actualCore.rules)
        let expectedRules = Set(expectedCore.rules)
        actualCore.rules = []
        expectedCore.rules = []

        #expect(actualCore == expectedCore)
        #expect(actualRules == expectedRules)
    }
}
