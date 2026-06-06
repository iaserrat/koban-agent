import Foundation

/// Evaluates a ruleset against a batch of inventory changes and raises findings. Pure and
/// deterministic: the caller supplies the ruleset, the changes, the timestamp, and an id
/// source, so the engine itself touches no IO or clock (see CLAUDE.md).
enum HeuristicEngine {
    static func evaluate(
        rules: [HeuristicRule],
        changes: [InventoryChange],
        timestamp: Date,
        makeID: () -> UUID
    ) -> [Finding] {
        var findings: [Finding] = []
        for change in changes {
            for rule in rules where applies(rule, to: change) {
                findings.append(finding(from: rule, change: change, timestamp: timestamp, id: makeID()))
            }
        }
        return findings
    }

    private static func applies(_ rule: HeuristicRule, to change: InventoryChange) -> Bool {
        rule.enabled
            && rule.surface == change.item.surface
            && rule.triggers.contains(change.kind)
            && rule.match.matches(change.item)
    }

    private static func finding(
        from rule: HeuristicRule,
        change: InventoryChange,
        timestamp: Date,
        id: UUID
    ) -> Finding {
        let matched = rule.match.matchedField(in: change.item)
        return Finding(
            id: id,
            timestamp: timestamp,
            surface: rule.surface,
            itemID: change.item.id,
            ruleID: rule.id,
            title: rule.title,
            rationale: rule.rationale,
            severity: rule.severity,
            itemName: change.item.name,
            evidence: FindingEvidence(
                path: change.item.path,
                detail: change.item.provenance.detail,
                matchedField: matched?.field,
                matchedValue: matched?.value
            )
        )
    }
}
