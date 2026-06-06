import Foundation
import Testing
@testable import Koban_Agent

struct DefaultHeuristicRulesTests {
    private let timestamp = Date(timeIntervalSince1970: 0)

    @Test
    func defaultRulesFlagAgentConfigAcrossSurfaces() {
        let changes = HeuristicConstants.agentConfigSurfaces.map { surface in
            InventoryChange(
                kind: .added,
                item: Fixture.item(surface: surface, kind: .mcpServer, name: surface.rawValue),
                previous: nil
            )
        }
        let findings = HeuristicEngine.evaluateChanges(
            rules: DefaultConfiguration.value.rules,
            changes: changes,
            timestamp: timestamp,
            makeID: UUID.init
        )
        let surfaces = Set(findings
            .filter { $0.ruleID == RuleID.agentNewMCPServer }
            .map(\.surface))
        #expect(surfaces == Set(HeuristicConstants.agentConfigSurfaces))
    }

    @Test
    func defaultRulesFlagNewPackageMetadata() {
        let changes = [
            InventoryChange(
                kind: .added,
                item: Fixture.item(surface: .javascriptPackages, kind: .package, name: "left-pad"),
                previous: nil
            ),
            InventoryChange(
                kind: .added,
                item: Fixture.item(surface: .pythonPackages, kind: .pythonResolvedPackage, name: "django"),
                previous: nil
            )
        ]
        let findings = HeuristicEngine.evaluateChanges(
            rules: DefaultConfiguration.value.rules,
            changes: changes,
            timestamp: timestamp,
            makeID: UUID.init
        )
        let ruleIDs = Set(findings.map(\.ruleID))
        #expect(ruleIDs.contains(RuleID.packagesNewJavaScriptPackage))
        #expect(ruleIDs.contains(RuleID.packagesNewPythonPackage))
    }

    @Test
    func defaultRulesFlagDynamicAuthHelperAcrossAgentSurfaces() {
        let changes = HeuristicConstants.agentConfigSurfaces.map { surface in
            InventoryChange(
                kind: .added,
                item: Fixture.item(
                    surface: surface,
                    kind: .mcpServer,
                    name: surface.rawValue,
                    detail: "https://mcp.example.com headersHelper"
                ),
                previous: nil
            )
        }
        let findings = HeuristicEngine.evaluateChanges(
            rules: DefaultConfiguration.value.rules,
            changes: changes,
            timestamp: timestamp,
            makeID: UUID.init
        )
        let surfaces = Set(findings
            .filter { $0.ruleID == RuleID.agentDynamicAuthHelper }
            .map(\.surface))
        #expect(surfaces == Set(HeuristicConstants.agentConfigSurfaces))
    }
}
