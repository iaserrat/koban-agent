import AppKit

/// The agent's entry point. Koban is a pure AppKit menu-bar agent: it has no SwiftUI `Scene`
/// (both the status-bar popover and the extended window are AppKit, hosting SwiftUI views via
/// `NSHostingController`), so it owns its startup directly rather than through a SwiftUI `App`,
/// which would require a scene we no longer have. `LSUIElement` (build settings) keeps it out of
/// the Dock and app switcher; `AppDelegate` builds the UI in `applicationDidFinishLaunching`.
@main
enum KobanApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        // NSApplication.delegate is weak; this local retains it for the process lifetime because
        // run() blocks until the app terminates.
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }
}
