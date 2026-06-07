import Testing
@testable import Koban_Agent

@MainActor
struct AppDelegateConfigurationReloadGuardTests {
    @Test
    func dropsAReloadThatStartsWhileAnotherIsApplying() async {
        let delegate = AppDelegate()
        var reentrantResult: Bool?

        // While the outer reload is mid-apply the guard is held, so a reload that begins now (a
        // sync reset racing a file-watcher or remote push) must be turned away rather than starting
        // a second, interleaving engine restart.
        let outerRan = await delegate.runGuardedConfigurationReload {
            reentrantResult = await delegate.runGuardedConfigurationReload {}
        }

        #expect(outerRan)
        #expect(reentrantResult == false)
    }

    @Test
    func allowsSequentialReloadsOnceTheGuardIsReleased() async {
        let delegate = AppDelegate()

        let first = await delegate.runGuardedConfigurationReload {}
        let second = await delegate.runGuardedConfigurationReload {}

        #expect(first)
        #expect(second)
    }
}
