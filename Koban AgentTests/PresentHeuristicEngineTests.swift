import Foundation
import Testing
@testable import Koban_Agent

struct PresentHeuristicEngineTests {
    private let timestamp = Date(timeIntervalSince1970: 0)

    @Test
    func raisesFindingForMatchingPresentRule() {
        let rule = HeuristicRule(
            id: "present.rule",
            surface: .homebrew,
            enabled: true,
            triggers: [.present],
            match: .fieldContainsAny(field: .name, values: ["copilot-for-xcode"]),
            severity: .critical,
            title: "T",
            rationale: "R"
        )
        let findings = HeuristicEngine.evaluatePresentItems(
            rules: [rule],
            items: [Fixture.item(surface: .homebrew, name: "copilot-for-xcode")],
            timestamp: timestamp,
            makeID: UUID.init
        )
        #expect(findings.count == 1)
        #expect(findings.first?.itemName == "copilot-for-xcode")
        #expect(findings.first?.severity == .critical)
    }

    @Test
    func presentEvaluationSkipsChangeOnlyRulesAndWrongSurface() {
        let base = HeuristicRule(
            id: "present.rule",
            surface: .homebrew,
            enabled: true,
            triggers: [.present],
            match: .always,
            severity: .critical,
            title: "T",
            rationale: "R"
        )
        var changeOnly = base
        changeOnly.triggers = [.added]
        var wrongSurface = base
        wrongSurface.surface = .claudeConfig

        let findings = HeuristicEngine.evaluatePresentItems(
            rules: [changeOnly, wrongSurface],
            items: [Fixture.item(surface: .homebrew, name: "copilot-for-xcode")],
            timestamp: timestamp,
            makeID: UUID.init
        )
        #expect(findings.isEmpty)
    }
}
