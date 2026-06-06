import SwiftUI

/// Shown in place of the window's content when the database could not be opened, so monitoring
/// is disabled. An honest state, not a blank window.
struct WindowUnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Monitoring unavailable",
            systemImage: Symbols.shield,
            description: Text("Koban could not open its database, so there is nothing to show.")
        )
    }
}
