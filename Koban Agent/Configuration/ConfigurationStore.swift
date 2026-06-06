import Observation
import OSLog

/// Owns the two-way sync between the Settings UI and `koban.yaml`. `saved` is what is on disk;
/// `draft` is what the form edits. Saving writes the file and applies the config to the running
/// engine; an external change to the file reloads it. `@MainActor` because the UI binds it; the
/// single source of config truth for the UI, the role `AppState` plays for monitor data.
@MainActor
@Observable
final class ConfigurationStore {
    /// The configuration last known to be on disk (and applied to the engine).
    private(set) var saved: KobanConfiguration

    /// The editable copy the Settings form binds to.
    var draft: KobanConfiguration

    /// Set when the file changed on disk while the user had unsaved edits, so the UI can offer to
    /// reload or keep the in-progress draft instead of silently discarding either.
    private(set) var externalChangeWhileEditing = false

    private let fileURL: URL
    private let onApply: (KobanConfiguration) -> Void

    init(
        initial: KobanConfiguration,
        fileURL: URL = ConfigPaths.userConfigFile(),
        onApply: @escaping (KobanConfiguration) -> Void
    ) {
        saved = initial
        draft = initial
        self.fileURL = fileURL
        self.onApply = onApply
    }

    var isDirty: Bool {
        draft != saved
    }

    /// Writes the draft and applies it. On a write failure we keep the draft dirty and surface
    /// nothing as saved, so the user can retry rather than believing a failed write succeeded.
    func save() {
        do {
            try ConfigurationWriter.write(draft, to: fileURL)
        } catch {
            Log.configuration.error("Could not write config: \(String(describing: error), privacy: .public).")
            return
        }
        saved = draft
        externalChangeWhileEditing = false
        onApply(draft)
    }

    /// Discards the draft, returning to the last saved configuration (and the file on disk).
    func revert() {
        draft = saved
        externalChangeWhileEditing = false
    }

    /// Keeps the in-progress draft after an external change, dismissing the conflict notice. The
    /// next `save()` will overwrite the on-disk change with the draft.
    func keepDraftOverExternalChange() {
        externalChangeWhileEditing = false
    }

    /// Called when the file changes on disk. If it matches what we last saved, it is our own write
    /// echoing back through FSEvents: ignore it, so there is no reload and no second engine
    /// restart. Otherwise adopt it when the user has no unsaved edits; if they do, flag the
    /// conflict and let the UI decide.
    func externalReload() {
        let onDisk = ConfigurationLoader.load(from: fileURL)
        guard onDisk != saved else { return }
        let hadUnsavedEdits = isDirty
        saved = onDisk
        if hadUnsavedEdits {
            externalChangeWhileEditing = true
        } else {
            draft = onDisk
            onApply(onDisk)
        }
    }
}
