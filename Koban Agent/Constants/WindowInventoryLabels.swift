enum WindowInventoryLabels {
    static let loadMore = "Load more"
    static let loading = "Loading"
    static let searchPrompt = "Search by name"

    static func loadedCount(loaded: Int, total: Int) -> String {
        "\(loaded) of \(total)"
    }
}
