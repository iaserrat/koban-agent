import Foundation

/// How the Settings sidebar clusters its categories: the monitoring pipeline, the watched
/// ecosystems, and the heuristic ruleset. Each group titles a labelled block in the sidebar, the
/// same grouping a System Settings sidebar uses to keep a long list legible.
enum SettingsCategoryGroup: String, CaseIterable, Identifiable {
    case pipeline
    case ecosystems
    case rules

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .pipeline: "Pipeline"
        case .ecosystems: "Ecosystems"
        case .rules: "Rules"
        }
    }
}
