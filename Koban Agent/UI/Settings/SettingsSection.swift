import SwiftUI

/// A titled group of settings rows. One container so every section's heading and rhythm match.
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Metrics.settingsRowSpacing) {
            SectionLabel(title: title)
            content
        }
    }
}
