import Foundation
import Testing
@testable import Koban_Agent

// MARK: - ConfigurationStoreTests

/// The two-way sync contract: dirty tracking, saving, and how external file changes reconcile
/// against in-progress edits. Driven against a temp file so it stays filesystem-isolated.
@MainActor
struct ConfigurationStoreTests {
    /// Records the configs handed to `onApply` so tests can assert the engine would (not) reload.
    private final class ApplyRecorder {
        var applied: [KobanConfiguration] = []
    }

    private func makeStore(
        url: URL,
        initial: KobanConfiguration = DefaultConfiguration.value
    ) -> (ConfigurationStore, ApplyRecorder) {
        let recorder = ApplyRecorder()
        let store = ConfigurationStore(initial: initial, fileURL: url) { recorder.applied.append($0) }
        return (store, recorder)
    }

    private func tunedConfig(debounce: Int) -> KobanConfiguration {
        var config = DefaultConfiguration.value
        config.watch.debounceMilliseconds = debounce
        return config
    }

    @Test
    func isDirtyTracksDraftAgainstSaved() async {
        await Fixture.withTemporaryDirectory { directory in
            let (store, _) = makeStore(url: directory.appending(path: "koban.yaml"))
            #expect(store.isDirty == false)

            store.draft.watch.debounceMilliseconds = 1234
            #expect(store.isDirty)

            store.revert()
            #expect(store.isDirty == false)
        }
    }

    @Test
    func saveWritesFileAppliesAndClearsDirty() async {
        await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            let (store, recorder) = makeStore(url: url)

            store.draft.watch.debounceMilliseconds = 4321
            store.save()

            #expect(store.isDirty == false)
            #expect(recorder.applied.count == 1)
            let reloaded = ConfigurationLoader.load(from: url)
            #expect(reloaded.watch.debounceMilliseconds == 4321)
        }
    }

    @Test
    func externalReloadIgnoresOurOwnWrite() async {
        await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            let (store, recorder) = makeStore(url: url)

            store.draft.watch.debounceMilliseconds = 55
            store.save()
            #expect(recorder.applied.count == 1)

            // The file on disk equals `saved`, so this is our write echoing back: no reload.
            store.externalReload()
            #expect(recorder.applied.count == 1)
            #expect(store.externalChangeWhileEditing == false)
        }
    }

    @Test
    func externalReloadAdoptsChangeWhenClean() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            let (store, recorder) = makeStore(url: url)

            try ConfigurationWriter.write(tunedConfig(debounce: 999), to: url)
            store.externalReload()

            #expect(store.saved.watch.debounceMilliseconds == 999)
            #expect(store.draft.watch.debounceMilliseconds == 999)
            #expect(recorder.applied.count == 1)
            #expect(store.externalChangeWhileEditing == false)
        }
    }

    @Test
    func externalReloadFlagsConflictWhenDirty() async throws {
        try await Fixture.withTemporaryDirectory { directory in
            let url = directory.appending(path: "koban.yaml")
            let (store, recorder) = makeStore(url: url)

            store.draft.watch.debounceMilliseconds = 111 // unsaved edit
            try ConfigurationWriter.write(tunedConfig(debounce: 222), to: url)

            store.externalReload()

            #expect(store.externalChangeWhileEditing)
            #expect(store.draft.watch.debounceMilliseconds == 111) // draft preserved
            #expect(store.saved.watch.debounceMilliseconds == 222) // saved tracks disk
            #expect(recorder.applied.isEmpty) // engine not reloaded mid-edit
        }
    }
}
