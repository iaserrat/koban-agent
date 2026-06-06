import Foundation

struct InventorySearchText: Codable, Hashable {
    let rawValue: String

    init(_ rawValue: String = "") {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        rawValue.isEmpty
    }

    var ftsQuery: String? {
        let tokens = rawValue
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.isEmpty == false }
            .map { $0 + InventorySearchQuerySyntax.tokenSuffix }
        guard tokens.isEmpty == false else { return nil }
        return tokens.joined(separator: InventorySearchQuerySyntax.tokenSeparator)
    }

    static let empty = Self()
}
