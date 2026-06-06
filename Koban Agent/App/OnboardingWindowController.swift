import AppKit
import SwiftUI

/// Owns the first-run onboarding window using public AppKit API (`NSWindow` +
/// `NSHostingController`), the same bridge the extended window uses.
///
/// Koban normally runs as `.accessory` (no Dock icon, no app-switcher entry). The first-run flow is
/// the one moment the agent asks for the user's attention, so while the window is open we promote
/// to `.regular` and activate, then drop back to `.accessory` when it closes. The window is a fixed,
/// chromeless card, always centred: the standard window buttons are hidden and it is not movable, so
/// the flow reads as a single focused surface rather than a draggable document window. Advancing
/// through the steps (or Quit) is the only way out, which is the intent of a first run.
@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private let rootView: OnboardingRootView
    private var window: NSWindow?

    init(rootView: OnboardingRootView) {
        self.rootView = rootView
        super.init()
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        // Re-centre on every show so the card lands centred even if the active display or its
        // resolution changed since it was built.
        centerOnScreen(window)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(
                origin: .zero,
                size: NSSize(width: Metrics.onboardingWindowWidth, height: Metrics.onboardingWindowHeight)
            ),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        let hosting = NSHostingController(rootView: rootView)
        // Size the window ourselves rather than letting the hosting controller drive it: assigning a
        // controller resizes the window to the SwiftUI fitting size, and `.preferredContentSize`
        // applies that asynchronously after layout, which lands the window off-centre. We set the
        // exact, fixed card size here so the size is known up front and `centerOnScreen` can place it
        // precisely with nothing resizing it afterwards.
        hosting.sizingOptions = []
        window.contentViewController = hosting
        window.setContentSize(NSSize(
            width: Metrics.onboardingWindowWidth,
            height: Metrics.onboardingWindowHeight
        ))
        window.title = "Welcome to Koban"
        // A chromeless card: the content fills the window under a transparent, text-free title bar,
        // and the three standard window buttons are hidden, so no traffic lights sit over the flow.
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        // Fixed and centred: the user cannot drag it off-centre, so it stays put for the flow.
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.delegate = self
        centerOnScreen(window)
        return window
    }

    /// Places the card at the true centre of the active screen's visible area (inside the menu bar
    /// and Dock). `NSWindow.center()` biases toward the upper third, so we compute the centred frame
    /// from the known card size instead.
    private func centerOnScreen(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let size = NSSize(
            width: Metrics.onboardingWindowWidth,
            height: Metrics.onboardingWindowHeight
        )
        // A card rect at the origin: its `midX`/`midY` give half the card's size, so subtracting
        // them from the screen centre yields the centred origin without a bare divisor.
        let card = NSRect(origin: .zero, size: size)
        let visible = screen.visibleFrame
        let origin = NSPoint(x: visible.midX - card.midX, y: visible.midY - card.midY)
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
