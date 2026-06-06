import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ConfigurationDecodingTests

/// Exercises the `Decodable` conformances (the same logic Yams drives at runtime) via JSON, so
/// the tests need no YAML dependency.
struct ConfigurationDecodingTests {
    private func decode(_ json: String) throws -> KobanConfiguration {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(KobanConfiguration.self, from: data)
    }

    @Test
    func omittedSectionsFallBackToDefaults() throws {
        let config = try decode(#"{"watch": {"debounceMilliseconds": 100, "pollIntervalSeconds": 10}}"#)
        #expect(config.watch.debounceMilliseconds == 100)
        #expect(
            config.watch.maxScanWallClockSeconds
                == DefaultConfiguration.value.watch.maxScanWallClockSeconds
        )
        #expect(
            config.watch.maxFreshScanAgeSeconds
                == DefaultConfiguration.value.watch.maxFreshScanAgeSeconds
        )
        #expect(
            config.watch.projectDiscovery.roots == DefaultConfiguration.value.watch.projectDiscovery.roots
        )
        #expect(config.watch.homeSignalScan.enabled == false)
        #expect(config.persistence == DefaultConfiguration.value.persistence)
        #expect(config.rules == DefaultConfiguration.value.rules)
        #expect(config.homebrew.enabled == DefaultConfiguration.value.homebrew.enabled)
    }

    @Test
    func decodesV1SurfaceSettings() throws {
        let json = #"""
        {
          "claude": {
            "enabled": false,
            "includeHooks": false,
            "includeManagedSettings": true,
            "projectRoots": ["~/work"]
          },
          "codex": {"enabled": false, "includeSystemConfig": true},
          "pi": {"enabled": false, "agentDirectory": "~/.pi/custom"},
          "cursor": {"enabled": false, "includeRules": false},
          "opencode": {"enabled": false, "includeManagedPreferences": true},
          "javascript": {"enabled": false, "includeBun": false},
          "python": {"enabled": false, "includeRequirements": false}
        }
        """#
        let config = try decode(json)
        #expect(config.claude.enabled == false)
        #expect(config.claude.includeHooks == false)
        #expect(config.claude.includeManagedSettings)
        #expect(config.claude.projectRoots == ["~/work"])
        #expect(config.codex.enabled == false)
        #expect(config.codex.includeSystemConfig)
        #expect(config.pi.agentDirectory == "~/.pi/custom")
        #expect(config.cursor.includeRules == false)
        #expect(config.opencode.includeManagedPreferences)
        #expect(config.javascript.includeBun == false)
        #expect(config.python.includeRequirements == false)
    }

    @Test
    func decodesHomeSignalScanDefaultsAndOverrides() throws {
        let json = #"""
        {
          "watch": {
            "homeSignalScan": {
              "enabled": true,
              "maxDepth": 4,
              "initialScanBudget": {
                "maxDirectoriesVisited": 20
              }
            }
          }
        }
        """#
        let config = try decode(json)
        #expect(config.watch.homeSignalScan.enabled)
        #expect(config.watch.homeSignalScan.root == "~")
        #expect(config.watch.homeSignalScan.maxDepth == 4)
        #expect(config.watch.homeSignalScan.initialScanBudget.maxDirectoriesVisited == 20)
        #expect(config.watch.homeSignalScan.initialScanBudget.maxFilesVisited == 250_000)
        #expect(config.watch.homeSignalScan.pruneDirectoryNames.contains("node_modules"))
    }

    @Test
    func decodesScanWallClockBudget() throws {
        let config = try decode(#"{"watch": {"maxScanWallClockSeconds": 7}}"#)

        #expect(config.watch.maxScanWallClockSeconds == 7)
    }

    @Test
    func decodesFreshScanAgeBudget() throws {
        let config = try decode(#"{"watch": {"maxFreshScanAgeSeconds": 30}}"#)

        #expect(config.watch.maxFreshScanAgeSeconds == 30)
    }

    @Test
    func decodesPersistenceRetentionBudgets() throws {
        let config = try decode(
            #"{"persistence": {"maxStoredEvents": 8, "maxStoredFindings": 3}}"#
        )

        #expect(config.persistence.maxStoredEvents == 8)
        #expect(config.persistence.maxStoredFindings == 3)
    }

    @Test
    func decodesSyncSettingsAndDefaults() throws {
        let config = try decode(
            #"{"sync": {"enabled": true, "endpoint": "https://fleet.example.test", "maxBatchEvents": 10}}"#
        )

        #expect(config.sync.enabled)
        #expect(config.sync.protocolName == ConfigurationDefaults.syncProtocolName)
        #expect(config.sync.endpoint == "https://fleet.example.test")
        #expect(config.sync.maxBatchBytes == ConfigurationDefaults.syncMaxBatchBytes)
        #expect(config.sync.maxBatchEvents == 10)
        #expect(config.sync.checkInIntervalSeconds == ConfigurationDefaults.syncCheckInIntervalSeconds)
    }

    @Test
    func decodesCustomRuleWithMatchParameters() throws {
        let json = #"""
        {
          "rules": [
            {
              "id": "custom.contains",
              "surface": "homebrew",
              "severity": "suspicious",
              "title": "Custom",
              "rationale": "Why",
              "match": "fieldContainsAny",
              "field": "name",
              "values": ["sketchy"]
            }
          ]
        }
        """#
        let config = try decode(json)
        #expect(config.rules.count == 1)
        let rule = try #require(config.rules.first)
        #expect(rule.enabled)
        #expect(rule.triggers == [.added, .modified])
        #expect(rule.match.matches(Fixture.item(name: "sketchy-tool")))
        #expect(rule.match.matches(Fixture.item(name: "ripgrep")) == false)
    }

    @Test
    func rejectsRuleMissingRequiredMatchParameter() {
        let json = #"""
        {"rules": [{"id": "x", "surface": "homebrew", "severity": "info",
        "title": "T", "rationale": "R", "match": "fieldContainsAny", "field": "name"}]}
        """#
        #expect(throws: (any Error).self) {
            try decode(json)
        }
    }
}
