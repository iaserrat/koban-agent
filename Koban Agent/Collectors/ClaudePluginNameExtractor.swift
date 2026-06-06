enum ClaudePluginNameExtractor {
    static func names(from value: Any?) -> [String] {
        if let dictionary = value as? [String: Any] {
            return dictionary.keys.sorted()
        }
        if let array = value as? [[String: Any]] {
            let names = array.compactMap { entry in
                entry[ClaudeConfigNames.nameKey] as? String
                    ?? entry[ClaudeConfigNames.sourceKey] as? String
                    ?? entry[ClaudeConfigNames.pathKey] as? String
            }
            return names.sorted()
        }
        if let array = value as? [String] {
            return array.sorted()
        }
        return []
    }
}
