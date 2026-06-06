import SwiftUI

/// The quit control. An agent app has no Dock icon, so this is the user's way out - always
/// one obvious click away (see CLAUDE.md).
struct QuitFooter: View {
    var body: some View {
        RowButton {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack(spacing: Metrics.spacingSmall) {
                Image(systemName: Symbols.quit)
                    .frame(width: Metrics.iconWidth)
                Text("Quit Koban")
            }
        }
    }
}
