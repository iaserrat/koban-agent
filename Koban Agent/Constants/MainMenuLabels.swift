import Foundation

/// Titles and key equivalents for the app's main menu. As a hand-rolled AppKit agent Koban builds
/// its own menu (`MainMenu`), so these standard editing labels live here rather than coming from a
/// storyboard or SwiftUI `App`. The single home for these literals (see CLAUDE.md).
enum MainMenuLabels {
    static let appMenuTitle = "Koban"
    static let quit = "Quit Koban"
    static let quitKey = "q"

    static let edit = "Edit"
    static let undo = "Undo"
    static let undoKey = "z"
    static let redo = "Redo"
    static let redoKey = "z"
    static let cut = "Cut"
    static let cutKey = "x"
    static let copy = "Copy"
    static let copyKey = "c"
    static let paste = "Paste"
    static let pasteKey = "v"
    static let selectAll = "Select All"
    static let selectAllKey = "a"
}
