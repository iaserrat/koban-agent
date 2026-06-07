import SwiftUI

/// The monitor window's top bar: the Koban mark, the scope switch, the live monitoring state, the
/// row count, and a search field. The full-size content view's title-bar safe area already drops it
/// below the floating traffic lights, so it starts flush at the shared content margin.
struct MonitorToolbar: View {
    @Binding var scope: MonitorScope
    @Binding var searchText: String
    @Binding var isShowingSettings: Bool
    let showsSettingsButton: Bool
    let isMonitoring: Bool
    /// Whether the current scope drives the stream table. The home dashboard has no table, so it
    /// hides the row count and the search field while keeping the scope switch and live state.
    let showsStreamControls: Bool
    let count: Int
    let noun: String

    var body: some View {
        HStack(spacing: Metrics.spacingMedium) {
            brand
            divider
            if isShowingSettings {
                backControl
                Spacer(minLength: Metrics.spacingMedium)
            } else {
                MonitorScopePicker(scope: $scope)
                Spacer(minLength: Metrics.spacingMedium)
                live
                if showsStreamControls {
                    count(count, noun)
                    search
                }
            }
            if showsSettingsButton {
                settingsButton
            }
        }
        .padding(.leading, Metrics.spacingLarge)
        .padding(.trailing, Metrics.spacingLarge)
        .frame(height: Metrics.toolbarHeight)
        .background(Palette.bgDeep)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: Metrics.hairline)
        }
    }

    private var brand: some View {
        HStack(spacing: Metrics.spacingSmall) {
            RoundedRectangle(cornerRadius: Metrics.chipCornerRadius, style: .continuous)
                .fill(Palette.accent)
                .frame(width: Metrics.brandMarkSize, height: Metrics.brandMarkSize)
                .overlay(
                    BrandMark(size: Metrics.monogramFontSize)
                        .foregroundStyle(.white)
                )
            Text("Koban")
                .font(.headline)
                .foregroundStyle(Palette.ink)
        }
    }

    private var backControl: some View {
        Button {
            isShowingSettings = false
        } label: {
            HStack(spacing: Metrics.spacingTight) {
                Image(systemName: Symbols.settingsBack)
                Text("Settings")
                    .fontWeight(.medium)
            }
            .font(.callout)
            .foregroundStyle(Palette.ink)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings.toggle()
        } label: {
            Image(systemName: Symbols.settings)
                .foregroundStyle(isShowingSettings ? Palette.accent : Palette.inkMuted)
                .frame(width: Metrics.iconWidth, height: Metrics.iconWidth)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.borderStrong)
            .frame(width: Metrics.hairline, height: Metrics.iconWidth)
    }

    private var live: some View {
        HStack(spacing: Metrics.spacingSmall) {
            StatusDot(color: isMonitoring ? Palette.accent : Palette.inkSubtle)
            Text(isMonitoring ? "Monitoring" : "Idle")
                .font(.callout)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    private func count(_ count: Int, _ noun: String) -> some View {
        HStack(spacing: Metrics.spacingTight) {
            Text(count, format: .number)
                .font(.callout)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text(noun)
                .font(.callout)
                .foregroundStyle(Palette.inkSubtle)
        }
    }

    private var search: some View {
        HStack(spacing: Metrics.spacingSmall) {
            Image(systemName: Symbols.search)
                .foregroundStyle(Palette.inkSubtle)
            TextField("Filter by path or name", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, Metrics.chipPaddingH)
        .padding(.vertical, Metrics.segmentPaddingV)
        .frame(width: Metrics.toolbarSearchWidth)
        .background(
            RoundedRectangle(cornerRadius: Metrics.segmentGroupCornerRadius, style: .continuous)
                .fill(Palette.bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.segmentGroupCornerRadius, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: Metrics.hairline)
        )
    }
}
