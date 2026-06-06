import Testing
@testable import Koban_Agent

struct RuleFieldTests {
    @Test
    func exposesPackageSourceAndScopeDetails() {
        let item = Fixture.item(
            surface: .javascriptPackages,
            name: "left-pad",
            origin: PackageMetadataNames.npmManager,
            detail: "resolved=https://registry.npmjs.org/left-pad/-/left-pad-1.3.0.tgz scope=dev"
        )

        #expect(RuleField.packageManager.value(in: item) == PackageMetadataNames.npmManager)
        #expect(
            RuleField.sourceURL.value(in: item)
                == "https://registry.npmjs.org/left-pad/-/left-pad-1.3.0.tgz"
        )
        #expect(RuleField.registry.value(in: item) == "registry.npmjs.org")
        #expect(RuleField.dependencyScope.value(in: item) == PackageMetadataNames.devScope)
    }

    @Test
    func exposesCommandAndFileHashDetails() {
        let hash = String(repeating: "a", count: FileHashNames.digestLength)
        let commandItem = Fixture.item(
            surface: .codexConfig,
            kind: .mcpServer,
            name: "docs",
            origin: "npx",
            detail: "npx -y docs-mcp"
        )
        let fileItem = Fixture.item(
            surface: .cursorConfig,
            kind: .instruction,
            name: "AGENTS.md",
            detail: hash
        )

        #expect(RuleField.command.value(in: commandItem) == "npx")
        #expect(RuleField.fileHash.value(in: fileItem) == hash)
        #expect(RuleFlag.isExecutableConfig.value(in: commandItem) == true)
        #expect(RuleFlag.isPromptShapingConfig.value(in: fileItem) == true)
    }
}
