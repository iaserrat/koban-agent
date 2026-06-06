import AppKit
import SwiftUI

/// Owns the single extended window using public AppKit API (`NSWindow` + `NSHostingController`).
///
/// Koban is a menu-bar agent (`LSUIElement`), so it normally runs as `.accessory`: no Dock icon,
/// no app-switcher entry. While the window is open we promote the app to `.regular` so the window
/// can take focus and be Cmd-Tabbed like a real window, and drop back to `.accessory` when it
/// closes (`windowWillClose`). One reused window instance guarantees a single window and clean
/// deep-linking. The window is driven by AppKit rather than a SwiftUI `Window` scene so the
/// AppKit-hosted popover can open it directly, without SwiftUI's scene-only `openWindow`.
@MainActor
final class ExtendedWindowController: NSObject, NSWindowDelegate {
    private let rootView: WindowContentView
    private var window: NSWindow?

    init(rootView: WindowContentView) {
        self.rootView = rootView
        super.init()
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        // Build the window at its real size and style up front, before installing the hosting
        // controller. The `NSWindow(contentViewController:)` convenience initializer instead
        // sizes the window to the SwiftUI content's tiny fitting size and forces a relayout once
        // `setContentSize` runs - the source of the AppKit constraint and layout-recursion warnings.
        let window = NSWindow(
            contentRect: NSRect(
                origin: .zero,
                size: NSSize(width: Metrics.windowDefaultWidth, height: Metrics.windowDefaultHeight)
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        let hosting = NSHostingController(rootView: rootView)
        // Derive the window's minimum size from the SwiftUI content's own minimum: the monitor root
        // sets `.frame(minWidth:minHeight:)`, and `.minSize` turns that into the window's
        // `contentMinSize` automatically. We deliberately omit `.preferredContentSize` (the
        // default): pushing the content's *ideal* size onto the window makes the two fight during
        // live resize and trips AppKit's layout-recursion guard. The popover wants the opposite
        // (it hugs its content), which is why it keeps `.preferredContentSize`.
        hosting.sizingOptions = [.minSize]
        window.contentViewController = hosting
        window.title = "Koban"
        // Let the content fill the whole window and the traffic lights float over it, instead of a
        // separate title-bar strip. All public, documented `NSWindow` API: a full-size content
        // view under a transparent, text-free title bar. The window's rounded corners are the
        // standard OS-drawn ones.
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.setFrameAutosaveName(WindowID.main)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }

    func windowWillClose(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
