import Foundation

struct ProjectFileDiscoveryState {
    var result: ProjectFileDiscoveryResult
    var directoriesVisited: Int
    let startedAt: Date

    init(startedAt: Date) {
        result = ProjectFileDiscoveryResult(files: [], issues: [])
        directoriesVisited = 0
        self.startedAt = startedAt
    }
}
