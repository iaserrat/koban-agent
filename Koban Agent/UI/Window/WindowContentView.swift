import SwiftUI

/// The extended window's content, resolved from the app delegate. Reading `windowData` here in a
/// real view body means the window reflects the database the moment it opens during launch (the
/// delegate is `@Observable`). Hosted by `ExtendedWindowController` via `NSHostingController`.
struct WindowContentView: View {
    let appDelegate: AppDelegate

    var body: some View {
        if let data = appDelegate.windowData {
            MainWindowView(
                state: appDelegate.appState,
                model: appDelegate.model,
                data: data,
                configurationStore: appDelegate.configurationStore,
                updater: appDelegate.updater,
                resetSyncState: { try await appDelegate.resetSyncStateForSettings() }
            )
        } else {
            WindowUnavailableView()
        }
    }
}
