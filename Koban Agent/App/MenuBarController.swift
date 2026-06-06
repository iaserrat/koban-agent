import AppKit
import SwiftUI

/// Owns the status-bar item and its popover using public AppKit API (`NSStatusItem` +
/// `NSPopover`). We manage the popover ourselves, rather than SwiftUI's `MenuBarExtra`, because a
/// `.window`-style `MenuBarExtra` cannot be dismissed programmatically with any public API
/// (Apple feedback FB11984872). A `.transient` popover closes on outside clicks like a native
/// menu, and `dismiss()` closes it on handoff to the extended window (see CLAUDE.md).
@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init(contentViewController: NSViewController) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = contentViewController
        super.init()

        if let button = statusItem.button {
            let image = NSImage(named: ImageAssets.brandMark)
            if let image, image.size.height > 0 {
                let scale = MenuBarMetrics.iconHeight / image.size.height
                image.size = NSSize(width: image.size.width * scale, height: MenuBarMetrics.iconHeight)
            }
            image?.isTemplate = true
            image?.accessibilityDescription = "Koban"
            button.image = image
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
    }

    func dismiss() {
        if popover.isShown { popover.performClose(nil) }
    }

    /// Opens the popover under the status item. Used to reveal the panel right after onboarding so
    /// the user sees their freshly indexed Mac where Koban lives, without hunting for the icon.
    func show() {
        guard let button = statusItem.button, popover.isShown == false else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
