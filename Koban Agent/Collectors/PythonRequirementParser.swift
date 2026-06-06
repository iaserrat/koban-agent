import Foundation

// MARK: - PythonRequirementParser

/// Parses requirement and constraint text files.
struct PythonRequirementParser {
    func records(from url: URL, kind: InventoryKind) throws -> [PackageInventoryRecord] {
        try Task.checkCancellation()
        return try result(
            from: url,
            kind: kind,
            validator: PackageMetadataFileValidator()
        ).records
    }

    func result(
        from url: URL,
        kind: InventoryKind,
        validator: PackageMetadataFileValidator,
        budget: PythonRequirementParseBudget = .defaultValue
    ) throws -> PythonRequirementParseResult {
        try Task.checkCancellation()
        var context = PythonRequirementParseContext(
            root: url.deletingLastPathComponent(),
            validator: validator,
            budget: budget
        )
        return try result(from: url, kind: kind, visited: [], depth: 0, context: &context)
    }

    func requirement(from line: String) -> String? {
        let trimmed = normalizedRequirementLine(line)
        guard trimmed.isEmpty == false,
              trimmed.hasPrefix(PackageMetadataNames.pythonCommentPrefix) == false
        else { return nil }

        let editableTrimmed = trimmed.hasPrefix(PackageMetadataNames.pythonEditablePrefix)
            ? String(trimmed.dropFirst(PackageMetadataNames.pythonEditablePrefix.count))
            : trimmed
        guard editableTrimmed.hasPrefix(PackageMetadataNames.pythonOptionPrefix) == false else { return nil }
        if let range = editableTrimmed.range(of: PackageMetadataNames.pythonDirectReferenceSeparator) {
            return String(editableTrimmed[..<range.lowerBound])
        }
        guard let index = editableTrimmed.firstIndex(where: {
            PackageMetadataNames.pythonVersionCharacters.contains($0)
        }) else {
            return editableTrimmed
        }
        return String(editableTrimmed[..<index])
    }

    private func result(
        from url: URL,
        kind: InventoryKind,
        visited: Set<String>,
        depth: Int,
        context: inout PythonRequirementParseContext
    ) throws -> PythonRequirementParseResult {
        try Task.checkCancellation()
        guard visited.contains(url.path) == false else { return PythonRequirementParseResult() }
        let nextVisited = visited.union([url.path])
        var result = PythonRequirementParseResult()
        for line in try pythonRequirementLogicalLines(from: url) {
            try Task.checkCancellation()
            if let include = includeURL(
                from: line,
                directory: url.deletingLastPathComponent(),
                root: context.root
            ) {
                let included = try parseInclude(
                    include,
                    kind: kind,
                    visited: nextVisited,
                    depth: depth + 1,
                    context: &context
                )
                result.append(included)
                continue
            }
            guard let name = requirement(from: line) else { continue }
            result.records.append(record(name: name, path: url.path, kind: kind))
        }
        return result
    }

    private func parseInclude(
        _ include: (url: URL, kind: InventoryKind?),
        kind: InventoryKind,
        visited: Set<String>,
        depth: Int,
        context: inout PythonRequirementParseContext
    ) throws -> PythonRequirementParseResult {
        try Task.checkCancellation()
        guard visited.contains(include.url.path) == false else { return PythonRequirementParseResult() }
        guard canInclude(include.url, depth: depth, context: &context) else {
            return PythonRequirementParseResult(issues: [
                includeLimitIssue(at: include.url, context: context)
            ])
        }
        do {
            try Task.checkCancellation()
            if let issue = try context.validator.issueIfTooLarge(include.url) {
                return PythonRequirementParseResult(issues: [issue])
            }
            return try result(
                from: include.url,
                kind: include.kind ?? kind,
                visited: visited,
                depth: depth,
                context: &context
            )
        } catch let error as CancellationError {
            throw error
        } catch {
            return PythonRequirementParseResult(issues: [
                CollectorIssue(
                    path: include.url.path,
                    reason: String(describing: error)
                )
            ])
        }
    }

    private func includeURL(
        from line: String,
        directory: URL,
        root: URL
    ) -> (url: URL, kind: InventoryKind?)? {
        let trimmed = normalizedRequirementLine(line)
        let prefixes: [(String, InventoryKind?)] = [
            (PackageMetadataNames.pythonRequirementIncludePrefix, nil),
            (PackageMetadataNames.pythonLongRequirementIncludePrefix, nil),
            (PackageMetadataNames.pythonConstraintIncludePrefix, .pythonConstraint),
            (PackageMetadataNames.pythonLongConstraintIncludePrefix, .pythonConstraint)
        ]
        guard let prefix = prefixes.first(where: { trimmed.hasPrefix($0.0) }) else { return nil }
        let path = String(trimmed.dropFirst(prefix.0.count)).trimmingCharacters(in: .whitespaces)
        let url = directory.appending(path: path).standardizedFileURL
        guard isInsideRoot(url, root: root) else { return nil }
        return (url, prefix.1)
    }

    private func isInsideRoot(_ url: URL, root: URL) -> Bool {
        let rootComponents = root.standardizedFileURL.pathComponents
        let urlComponents = url.standardizedFileURL.pathComponents
        guard urlComponents.count >= rootComponents.count else { return false }
        return Array(urlComponents.prefix(rootComponents.count)) == rootComponents
    }
}

private func pythonRequirementLogicalLines(from url: URL) throws -> [String] {
    try Task.checkCancellation()
    let physicalLines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
    try Task.checkCancellation()
    var lines: [String] = []
    var current = ""
    for line in physicalLines.map(String.init) {
        try Task.checkCancellation()
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasSuffix(PackageMetadataNames.pythonLineContinuationSuffix) {
            current += trimmed.dropLast().trimmingCharacters(in: .whitespaces) + " "
        } else {
            lines.append(current + trimmed)
            current = ""
        }
    }
    if current.isEmpty == false {
        lines.append(current)
    }
    return lines
}

private func canInclude(
    _ url: URL,
    depth: Int,
    context: inout PythonRequirementParseContext
) -> Bool {
    let budget = context.budget
    guard depth <= budget.maxIncludeDepth else { return false }
    guard context.state.includedFilesVisited < budget.maxIncludedFiles else { return false }
    context.state.includedFilesVisited += 1
    return true
}

private func includeLimitIssue(
    at url: URL,
    context: PythonRequirementParseContext
) -> CollectorIssue {
    let budget = context.budget
    return CollectorIssue(
        path: url.path,
        reason: HealthMessages.pythonRequirementIncludeLimitReached(
            maxFiles: budget.maxIncludedFiles,
            maxDepth: budget.maxIncludeDepth
        )
    )
}

private func record(name: String, path: String, kind: InventoryKind) -> PackageInventoryRecord {
    PackageInventoryRecord(
        name: name,
        version: nil,
        manager: PackageMetadataNames.pipManager,
        detail: nil,
        path: path,
        kind: kind
    )
}

private func normalizedRequirementLine(_ line: String) -> String {
    line
        .components(separatedBy: PackageMetadataNames.pythonHashOptionPrefix)
        .first?
        .trimmingCharacters(in: .whitespaces) ?? ""
}
