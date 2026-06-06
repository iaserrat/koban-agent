import Foundation

enum AgentConfigFileHash {
    static func detail(
        for url: URL,
        validator: AgentConfigFileValidator = AgentConfigFileValidator()
    ) -> (detail: String?, issue: CollectorIssue?) {
        do {
            if let issue = try validator.issueIfTooLarge(url) {
                return (nil, issue)
            }
            let detail = try FileHash.sha256(url)
            return (detail, nil)
        } catch {
            return (
                nil,
                CollectorIssue(path: url.path, reason: HealthMessages.fileHashUnavailable(error: error))
            )
        }
    }
}
