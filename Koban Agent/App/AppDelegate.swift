import AppKit
import Observation
import OSLog
import SwiftUI

/// Boots the monitoring engine at launch and owns the app's two AppKit surfaces: the status-bar
/// popover and the extended window. As a menu-bar agent we start monitoring immediately,
/// independent of whether the popover is open. `@Observable` so the window picks up `windowData`
/// once the database opens during launch.
@MainActor
@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    /// Navigation intent shared between the glance panel and the extended window.
    let model = MonitorModel()

    /// First-run flow state, fed by the engine's indexing progress. Only used on the first launch.
    let onboarding = OnboardingModel()

    /// The extended window's data source. `nil` only when the database could not be opened, in
    /// which case the window shows an "unavailable" state and monitoring is disabled.
    private(set) var windowData: WindowDataModel?

    /// Backs the Settings page: the editable, file-synced configuration. `nil` only before launch
    /// wiring runs (e.g. under tests, where `applicationDidFinishLaunching` returns early).
    private(set) var configurationStore: ConfigurationStore?

    private var engine: MonitoringEngine?
    private var isReloadingConfiguration = false
    private var isTerminating = false
    @ObservationIgnored private var configurationFileWatcher: ConfigurationFileWatcher?
    private var onboardingStore: OnboardingStore?
    @ObservationIgnored private var menuBar: MenuBarController?
    /// Sparkle's updater, shared by the panel footer and the window's home dashboard. Created during
    /// `installMenuBar` (off the early-return test path) and read by `WindowContentView`.
    private(set) var updater: UpdaterModel?
    @ObservationIgnored private var windowController: ExtendedWindowController?
    @ObservationIgnored private var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_: Notification) {
        guard TestEnvironment.isRunningTests == false else { return }
        // A GUI-launched process inherits a soft open-file limit of 256; raise it before any
        // FSEvents streams or the SQLite pool open, so they cannot exhaust the table (see
        // FileDescriptorLimit).
        FileDescriptorLimit.raiseSoftLimitToSystemMaximum()
        // Koban is dark mode only, regardless of the system setting (see CLAUDE.md).
        NSApp.appearance = NSAppearance(named: .darkAqua)
        // Without a main menu, macOS has nowhere to route the standard editing key equivalents, so
        // Cmd-C/V/X are dead in every text field (see MainMenu). Install one before any UI shows.
        NSApp.mainMenu = MainMenu.make()
        startMonitoring()
        installMenuBar()
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        guard let engine, isTerminating == false else { return .terminateNow }
        isTerminating = true
        configurationFileWatcher?.stop()
        Task { @MainActor in
            await engine.stop()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    private func startMonitoring() {
        ConfigurationSeeder.seedIfNeeded()
        let configuration = ConfigurationLoader.load()
        installConfigurationSync(initial: configuration)
        Task {
            let bootstrapped = await SyncBootstrapper().bootstrap(configuration)
            await startMonitoring(configuration: bootstrapped)
        }
    }

    /// Wires the Settings page's two-way sync: the store the UI edits, and the file watcher that
    /// reloads it when `koban.yaml` changes underneath us. Saving the store (or an external edit)
    /// applies the new configuration to the running engine through `applyLocalConfiguration`.
    private func installConfigurationSync(initial: KobanConfiguration) {
        let store = ConfigurationStore(initial: initial) { [weak self] applied in
            Task { await self?.applyLocalConfiguration(applied) }
        }
        configurationStore = store
        let watcher = ConfigurationFileWatcher { [weak self] in
            Task { @MainActor in self?.configurationStore?.externalReload() }
        }
        watcher.start()
        configurationFileWatcher = watcher
    }

    /// Applies a locally edited configuration to the running engine: bootstrap it (sync may adjust
    /// it), then restart. Reuses the same stop-and-recreate path as a remote configuration update.
    private func applyLocalConfiguration(_ configuration: KobanConfiguration) async {
        await runGuardedConfigurationReload {
            let bootstrapped = await SyncBootstrapper().bootstrap(configuration)
            await self.restartEngine(with: bootstrapped)
        }
    }

    /// Serializes engine restarts so two stop-and-recreate sequences never interleave on the main
    /// actor (which would leak a still-running engine and double the FSEvents streams). Every
    /// restart path, local edit, remote push, and sync reset, runs through here. Returns `false`
    /// when a reload was already applying: coalescing callers ignore it, a user-initiated reset
    /// surfaces it rather than reporting a success it did not perform.
    @discardableResult
    func runGuardedConfigurationReload(_ apply: () async throws -> Void) async rethrows -> Bool {
        guard isReloadingConfiguration == false else { return false }
        isReloadingConfiguration = true
        defer { isReloadingConfiguration = false }
        try await apply()
        return true
    }

    /// Tears down the running engine and starts a fresh one on `configuration`. The single
    /// stop-and-recreate path shared by local edits and remote configuration updates.
    func restartEngine(with configuration: KobanConfiguration) async {
        await engine?.stop()
        engine = nil
        await startMonitoring(configuration: configuration)
    }

    private func startMonitoring(configuration: KobanConfiguration) async {
        do {
            let database = try AppDatabase.live()
            windowData = WindowDataModel(readModels: ReadModelStore(database: database))
            let store = OnboardingStore(database: database)
            onboardingStore = store
            // On error reading the flag, default to "complete" so a storage problem never traps the
            // user in the first-run flow; the engine still indexes silently.
            let needsOnboarding = ((try? store.isComplete()) ?? true) == false
            let engine = try MonitoringEngine(
                configuration: configuration,
                database: database,
                appState: appState,
                remoteConfigUpdateHandler: { [weak self] in
                    await self?.reloadRemoteConfiguration()
                },
                indexingProgress: needsOnboarding ? indexingProgress() : .silent
            )
            self.engine = engine
            if needsOnboarding { presentOnboarding() }
            Task { await engine.start() }
        } catch {
            Log.engine.error("Could not start monitoring: \(error). Monitoring disabled.")
        }
    }

    /// The first load's progress, routed to the onboarding model on the main actor. The engine
    /// calls these from its startup primer as each surface is baselined.
    private func indexingProgress() -> IndexingProgress {
        IndexingProgress(
            willBegin: { [weak self] surfaces in await self?.onboarding.beginIndexing(surfaces) },
            willIndex: { [weak self] surface in await self?.onboarding.markIndexing(surface) },
            didIndex: { [weak self] surface in await self?.onboarding.markIndexed(surface) },
            didComplete: { [weak self] in await self?.onboarding.completeIndexing() }
        )
    }

    private func presentOnboarding() {
        let root = OnboardingRootView(
            onboarding: onboarding,
            state: appState,
            onComplete: { [weak self] in self?.completeOnboarding() },
            onQuit: { NSApplication.shared.terminate(nil) }
        )
        let controller = OnboardingWindowController(rootView: root)
        onboardingWindowController = controller
        controller.show()
    }

    /// Records onboarding as done, closes the window, and opens the panel so the user lands on
    /// their freshly indexed Mac.
    private func completeOnboarding() {
        try? onboardingStore?.markComplete(at: Date())
        onboardingWindowController?.close()
        onboardingWindowController = nil
        menuBar?.show()
    }

    private func reloadRemoteConfiguration() async {
        await runGuardedConfigurationReload {
            let localConfiguration = ConfigurationLoader.load()
            do {
                guard let updated = try await RemoteConfigurationFetcher()
                    .configurationUpdate(from: localConfiguration)
                else {
                    Log.sync.info("Remote configuration update was requested but no new config was returned.")
                    return
                }
                await self.restartEngine(with: updated)
            } catch {
                Log.sync.error("Remote configuration reload failed: \(error).")
            }
        }
    }

    private func installMenuBar() {
        // Created here rather than at init so it stays off the early-return test path: building it
        // starts Sparkle's scheduled update checks, which only make sense for a real launch. Built
        // before the window controller so `WindowContentView` can read it for the home dashboard.
        let updater = UpdaterModel()
        self.updater = updater

        let windowController = ExtendedWindowController(rootView: WindowContentView(appDelegate: self))
        self.windowController = windowController

        let panel = MenuBarRootView(state: appState, model: model, updater: updater) { [weak self] in
            self?.menuBar?.dismiss()
            self?.windowController?.show()
        }
        let hosting = NSHostingController(rootView: panel)
        // NSPopover does not infer its size from SwiftUI content; this propagates the panel's
        // ideal size so the popover sizes and anchors correctly under the status item.
        hosting.sizingOptions = [.preferredContentSize]
        menuBar = MenuBarController(contentViewController: hosting)
    }
}
