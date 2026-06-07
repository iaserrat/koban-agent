import AppKit

/// Builds the app's main menu. Koban runs `NSApplication` directly (see `KobanApp`) with no
/// storyboard or SwiftUI `App`, so it gets no default menu, and without an Edit menu macOS has
/// nowhere to route the standard editing key equivalents: pressing Cmd-C/V/X in a text field does
/// nothing because `NSApplication` offers the keystroke to `mainMenu.performKeyEquivalent` first,
/// and an absent menu means it never becomes a `copy:`/`paste:`/`cut:` action down the responder
/// chain (right-click works because `NSTextView` supplies its own contextual menu).
///
/// The items target the first responder (`action` with a `nil` target), so one menu fixes every
/// text field in both the popover and the extended window. Key equivalents are honoured even while
/// the agent is `.accessory` and the menu bar is hidden.
enum MainMenu {
    static func make() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(appMenu())
        menu.addItem(editMenu())
        return menu
    }

    /// AppKit treats the first menu's submenu as the application menu, drawn under the app name when
    /// the window promotes us to `.regular`. Quit keeps the charter's "quitting is one obvious
    /// click away" promise while a window is frontmost.
    private static func appMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let submenu = NSMenu(title: MainMenuLabels.appMenuTitle)
        submenu.addItem(
            withTitle: MainMenuLabels.quit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: MainMenuLabels.quitKey
        )
        item.submenu = submenu
        return item
    }

    private static func editMenu() -> NSMenuItem {
        let item = NSMenuItem()
        let submenu = NSMenu(title: MainMenuLabels.edit)
        submenu.addItem(
            withTitle: MainMenuLabels.undo,
            action: Selector(("undo:")),
            keyEquivalent: MainMenuLabels.undoKey
        )
        let redo = submenu.addItem(
            withTitle: MainMenuLabels.redo,
            action: Selector(("redo:")),
            keyEquivalent: MainMenuLabels.redoKey
        )
        redo.keyEquivalentModifierMask = [.command, .shift]
        submenu.addItem(.separator())
        submenu.addItem(
            withTitle: MainMenuLabels.cut,
            action: #selector(NSText.cut(_:)),
            keyEquivalent: MainMenuLabels.cutKey
        )
        submenu.addItem(
            withTitle: MainMenuLabels.copy,
            action: #selector(NSText.copy(_:)),
            keyEquivalent: MainMenuLabels.copyKey
        )
        submenu.addItem(
            withTitle: MainMenuLabels.paste,
            action: #selector(NSText.paste(_:)),
            keyEquivalent: MainMenuLabels.pasteKey
        )
        submenu.addItem(
            withTitle: MainMenuLabels.selectAll,
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: MainMenuLabels.selectAllKey
        )
        item.submenu = submenu
        return item
    }
}
