import Foundation
import Testing
import Yams
@testable import Koban_Agent

// MARK: - ConfigurationRoundTripTests

/// The contract for the Settings UI's two-way sync: anything we can load we must be able to write
/// back and re-load unchanged. Guards that every `encode(to:)` mirrors its `init(from:)`,
/// including the two flattenings (`watch.projectDiscovery` and a rule's `match`).
struct ConfigurationRoundTripTests {
    private func roundTrip(_ configuration: KobanConfiguration) throws -> KobanConfiguration {
        let yaml = try ConfigurationWriter.encode(configuration)
        return try YAMLDecoder().decode(KobanConfiguration.self, from: Data(yaml.utf8))
    }

    @Test
    func typedDefaultsRoundTrip() throws {
        let original = DefaultConfiguration.value
        #expect(try roundTrip(original) == original)
    }

    @Test
    func shippedDefaultYAMLRoundTrips() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Koban Agent/Resources/koban.default.yaml")
        let original = try YAMLDecoder().decode(
            KobanConfiguration.self,
            from: Data(contentsOf: url)
        )
        #expect(try roundTrip(original) == original)
    }

    @Test
    func projectDiscoveryStaysFlattenedUnderWatch() throws {
        var config = DefaultConfiguration.value
        config.watch.projectDiscovery.roots = ["~/work", "~/oss"]
        config.watch.projectDiscovery.maxDepth = 3

        let yaml = try ConfigurationWriter.encode(config)
        let node = try Yams.compose(yaml: yaml)
        let watch = try #require(node?["watch"])
        // Flattened: the keys sit directly under `watch`, not under a `projectDiscovery` map.
        #expect(watch["projectRoots"] != nil)
        #expect(watch["projectDiscovery"] == nil)
        #expect(try roundTrip(config) == config)
    }

    @Test
    func everyMatchCaseRoundTrips() throws {
        let matches: [RuleMatch] = [
            .always,
            .fieldContainsAny(field: .detail, values: ["curl", "| sh"]),
            .fieldNotInList(field: .origin, allowed: ["homebrew/core"]),
            .fieldHasURLScheme(field: .detail, schemes: ["http", "https"]),
            .flagEquals(flag: .installedOnRequest, expected: false)
        ]
        var config = DefaultConfiguration.value
        config.rules = matches.enumerated().map { index, match in
            HeuristicRule(
                id: "test.rule.\(index)",
                surface: .homebrew,
                enabled: index.isMultiple(of: 2),
                triggers: [.added],
                match: match,
                severity: .notable,
                title: "Rule \(index)",
                rationale: "Because \(index)"
            )
        }
        let restored = try roundTrip(config)
        #expect(restored.rules == config.rules)
        #expect(restored.rules.map(\.match) == matches)
    }

    @Test
    func setOptionalsRoundTrip() throws {
        var config = DefaultConfiguration.value
        config.homebrew.prefixes = ["/opt/homebrew"]
        config.sync.endpoint = "https://fleet.example.test"
        config.claude.projectRoots = ["~/work"]
        #expect(try roundTrip(config) == config)
    }
}
