import Foundation

/// Built-in heuristic rules, mirrored for humans in `koban.default.yaml`.
enum DefaultHeuristicRules {
    static let value: [HeuristicRule] = agentRules + packageRules + homebrewRules

    private static let agentRules: [HeuristicRule] = HeuristicConstants.agentConfigSurfaces.flatMap {
        rules(for: $0)
    }

    private static func rules(for surface: MonitoredSurface) -> [HeuristicRule] {
        detailRules(for: surface) + kindRules(for: surface)
    }

    private static func detailRules(for surface: MonitoredSurface) -> [HeuristicRule] {
        [
            agentDetailRule(
                id: RuleID.agentEphemeralRunner,
                surface: surface,
                match: .fieldContainsAny(field: .detail, values: HeuristicConstants.ephemeralRunnerCommands),
                title: "Ephemeral package runner",
                rationale: "This agent configuration launches via an on-the-fly runner "
                    + "that executes code downloaded at start time."
            ),
            suspiciousCommandRule(for: surface),
            agentDetailRule(
                id: RuleID.agentRemoteTransport,
                surface: surface,
                match: .fieldHasURLScheme(field: .detail, schemes: HeuristicConstants.remoteTransportSchemes),
                title: "Remote configuration endpoint",
                rationale: "This agent configuration points at a remote endpoint."
            ),
            agentDetailRule(
                id: RuleID.agentDynamicAuthHelper,
                surface: surface,
                match: .fieldContainsAny(
                    field: .detail,
                    values: [HeuristicConstants.dynamicAuthHelperToken]
                ),
                title: "Dynamic MCP auth helper",
                rationale: "This MCP server runs a command to generate auth headers."
            )
        ]
    }

    private static func kindRules(for surface: MonitoredSurface) -> [HeuristicRule] {
        [
            agentKindRule(RuleID.agentNewMCPServer, surface, .mcpServer, "New MCP server"),
            agentKindRule(RuleID.agentNewHook, surface, .hook, "New agent hook"),
            agentKindRule(RuleID.agentNewSkill, surface, .skill, "New agent skill"),
            agentKindRule(RuleID.agentNewPlugin, surface, .plugin, "New agent plugin"),
            agentKindRule(RuleID.agentNewCommand, surface, .command, "New agent command"),
            agentKindRule(RuleID.agentNewRule, surface, .rule, "New agent rule"),
            agentKindRule(RuleID.agentNewInstruction, surface, .instruction, "New agent instruction"),
            agentKindRule(RuleID.agentNewSettings, surface, .settings, "New agent setting")
        ]
    }

    private static func agentKindRule(
        _ id: String,
        _ surface: MonitoredSurface,
        _ kind: InventoryKind,
        _ title: String
    ) -> HeuristicRule {
        HeuristicRule(
            id: id,
            surface: surface,
            enabled: true,
            triggers: [.added],
            match: .fieldContainsAny(field: .kind, values: [kind.rawValue]),
            severity: .notable,
            title: title,
            rationale: "A new behavior-affecting agent configuration item was added."
        )
    }

    private static func agentDetailRule(
        id: String,
        surface: MonitoredSurface,
        match: RuleMatch,
        title: String,
        rationale: String
    ) -> HeuristicRule {
        HeuristicRule(
            id: id,
            surface: surface,
            enabled: true,
            triggers: [.added, .modified],
            match: match,
            severity: .notable,
            title: title,
            rationale: rationale
        )
    }

    private static func suspiciousCommandRule(for surface: MonitoredSurface) -> HeuristicRule {
        HeuristicRule(
            id: RuleID.agentSuspiciousCommand,
            surface: surface,
            enabled: true,
            triggers: [.added, .modified],
            match: .fieldContainsAny(field: .detail, values: HeuristicConstants.suspiciousCommandTokens),
            severity: .suspicious,
            title: "Suspicious command",
            rationale: "This agent configuration contains shell constructs commonly used "
                + "to fetch and execute remote code."
        )
    }

    private static let packageRules: [HeuristicRule] = [
        HeuristicRule(
            id: RuleID.packagesNewJavaScriptPackage,
            surface: .javascriptPackages,
            enabled: true,
            triggers: [.added],
            match: .fieldContainsAny(field: .kind, values: [InventoryKind.package.rawValue]),
            severity: .info,
            title: "New JavaScript package",
            rationale: "A new JavaScript package appeared in project dependency metadata."
        ),
        HeuristicRule(
            id: RuleID.packagesNewPythonPackage,
            surface: .pythonPackages,
            enabled: true,
            triggers: [.added],
            match: .fieldContainsAny(field: .kind, values: pythonPackageKinds),
            severity: .info,
            title: "New Python package",
            rationale: "A new Python package appeared in project dependency metadata."
        )
    ]

    private static let pythonPackageKinds = [
        InventoryKind.pythonDeclaredRequirement.rawValue,
        InventoryKind.pythonResolvedPackage.rawValue,
        InventoryKind.pythonConstraint.rawValue
    ]

    private static let homebrewRules: [HeuristicRule] = [
        HeuristicRule(
            id: RuleID.homebrewUntrustedTap,
            surface: .homebrew,
            enabled: true,
            triggers: [.added, .modified],
            match: .fieldNotInList(field: .origin, allowed: HeuristicConstants.trustedHomebrewTaps),
            severity: .notable,
            title: "Third-party tap",
            rationale: "This package was installed from a tap other than Homebrew's official core/cask."
        ),
        HeuristicRule(
            id: RuleID.homebrewUnrequestedInstall,
            surface: .homebrew,
            enabled: true,
            triggers: [.added],
            match: .flagEquals(flag: .installedOnRequest, expected: false),
            severity: .info,
            title: "Pulled in as a dependency",
            rationale: "This package was not requested explicitly."
        )
    ]
}
